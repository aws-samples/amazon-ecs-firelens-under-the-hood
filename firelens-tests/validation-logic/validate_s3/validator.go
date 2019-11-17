package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
)

type Message struct {
	Log string
}

func main() {
	s3Client, err := getS3Client()
	if err != nil {
		exitErrorf("Unable to create new S3 client: %v", err)
	}

	bucket := os.Getenv("S3_BUCKET_NAME")

	if bucket == "" {
		exitErrorf("Bucket name required. Set the value for environment variable- S3_BUCKET_NAME")
	}

	response := getS3Objects(s3Client, bucket)

	validate(s3Client, response, bucket)
}

// Creates a new S3 Client
func getS3Client() (*s3.S3, error) {
	region := os.Getenv("AWS_REGION")

	if region == "" {
		exitErrorf("AWS Region required. Set the value for environment variable- AWS_REGION")
	}

	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(region)},
	)

	if err != nil {
		return nil, err
	}

	return s3.New(sess), nil
}

// Returns all the objects from a S3 bucket
func getS3Objects(s3Client *s3.S3, bucket string) *s3.ListObjectsV2Output {
	input := &s3.ListObjectsV2Input{
		Bucket:  aws.String(bucket),
		MaxKeys: aws.Int64(100),
		Prefix:  aws.String(os.Getenv("OBJECT_PREFIX")),
	}

	response, err := s3Client.ListObjectsV2(input)

	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case s3.ErrCodeNoSuchBucket:
				fmt.Println(s3.ErrCodeNoSuchBucket, aerr.Error())
			default:
				fmt.Println(aerr.Error())
			}
		} else {
			fmt.Println(err.Error())
		}
		exitErrorf("Error occured to get the objects from the specified bucket")
	}

	return response
}

// Validates the log messages
// Checks whether there are exactly 1000 log records which contains only integers [0 - 999]
// Because our log producer was designed in that way
func validate(s3Client *s3.S3, response *s3.ListObjectsV2Output, bucket string) {
	expectedCount, conversionError := strconv.Atoi(os.Getenv("TOTAL_EVENTS"))
	if conversionError != nil {
		fmt.Println("String to Int convertion Error:", conversionError)
	}

	events := make(map[int]bool)
	fmt.Printf("Got %d S3 Objects\n", len(response.Contents))

	for i := range response.Contents {
		input := &s3.GetObjectInput{
			Bucket: aws.String(bucket),
			Key:    response.Contents[i].Key,
		}
		obj := getS3Object(s3Client, input)

		dataByte, err := ioutil.ReadAll(obj.Body)
		if err != nil {
			fmt.Println("Error parsing GetObject response. %v", err)
		}

		data := strings.Split(string(dataByte), "\n")

		for _, d := range data {
			if d == "" {
				continue
			}

			var message Message

			decodeError := json.Unmarshal([]byte(d), &message)
			if decodeError != nil {
				fmt.Println("Json Unmarshal Error:", decodeError)
				fmt.Println("Failure on: " + d)
			}

			number, convertionError := strconv.Atoi(message.Log)
			if convertionError != nil {
				fmt.Println("String to Int convertion Error:", convertionError)
				fmt.Println("Failure on: " + message.Log)
			}
			// logger starts at 1, not 0
			events[number] = true
			if number > expectedCount {
				fmt.Printf("Error: %d is greater than %d\n", number, expectedCount)
			}
			if number < 0 {
				fmt.Printf("Error: %d is less than 0\n", number)
			}
		}

	}
	fmt.Println("Expected: " + strconv.Itoa(expectedCount))
	fmt.Println("Actual: " + strconv.Itoa(len(events)))
	if len(events) == expectedCount {
		fmt.Println("Validation Successful")
	} else {
		fmt.Println("Validation Failed. Number of missing log records: ", expectedCount-len(events))
	}

}

// Retrives a object from a S3 bucket
func getS3Object(s3Client *s3.S3, input *s3.GetObjectInput) *s3.GetObjectOutput {
	obj, err := s3Client.GetObject(input)

	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case s3.ErrCodeNoSuchKey:
				fmt.Println(s3.ErrCodeNoSuchKey, aerr.Error())
			default:
				fmt.Println(aerr.Error())
			}
		} else {
			fmt.Println(err.Error())
		}
		exitErrorf("Error occured to get s3 object: %v", err)
	}

	return obj
}

func exitErrorf(msg string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, msg+"\n", args...)
	os.Exit(1)
}
