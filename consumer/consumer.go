// Example function-based high-level Apache Kafka consumer
package main

/**
 * Copyright 2016 Confluent Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// consumer_example implements a consumer using the non-channel Poll() API
// to retrieve messages and events.

import (
	"fmt"
	"github.com/confluentinc/confluent-kafka-go/kafka"
	"os"
	"os/signal"
	"syscall"
	"time"
	"math/rand"
)

func main() {

	if len(os.Args) < 4 {
		fmt.Fprintf(os.Stderr, "Usage: %s <broker> <group> <topics..>\n",
			os.Args[0])
		os.Exit(1)
	}

	broker := os.Args[1]
	groupId := os.Args[2]
	instanceId := os.Args[3]
	topics := os.Args[4:]

	sigchan := make(chan os.Signal, 1)
	signal.Notify(sigchan, syscall.SIGINT, syscall.SIGTERM)

	consumer, err := kafka.NewConsumer(&kafka.ConfigMap{
		"bootstrap.servers": broker,
		// Avoid connecting to IPv6 brokers:
		// This is needed for the ErrAllBrokersDown show-case below
		// when using localhost brokers on OSX, since the OSX resolver
		// will return the IPv6 addresses first.
		// You typically don't need to specify this configuration property.
		"broker.address.family":           "v4",
		"group.id":                        groupId,
		"group.instance.id":               instanceId,
		"session.timeout.ms":              6000,
		"go.events.channel.enable":        false,
		"go.application.rebalance.enable": true,
		// Enable generation of PartitionEOF when the
		// end of a partition is reached.
		"enable.partition.eof":            true,
		"auto.offset.reset":               "latest"})

	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to create consumer: %s\n", err)
		os.Exit(1)
	}

	fmt.Printf("Created Consumer %v\n", consumer)

	err = consumer.SubscribeTopics(topics, nil)

	defer func() {
		fmt.Printf("Closing consumer\n")
		consumer.Close()
	}()

	run := true
	backoffCounter := 1

	for run {
		fmt.Println("Processing event stream...")
		select {
		case sig := <-sigchan:
			fmt.Printf("Caught signal %v: terminating\n", sig)
			run = false
		default:
			fmt.Println("Polling for latest events...")
			event := consumer.Poll(100)

			switch currentEvent := event.(type) {
			case *kafka.Message:
				fmt.Printf("%% Message on %s:\n%s\n",
					currentEvent.TopicPartition, string(currentEvent.Value))
				if currentEvent.Headers != nil {
					fmt.Printf("%% Headers: %v\n", currentEvent.Headers)
				}
				// reset backoffCounter when any message received.
				if backoffCounter > 1 {
					backoffCounter = 1
				} 
			case kafka.Error:
				// Errors should generally be considered
				// informational, the client will try to
				// automatically recover.
				// But in this example we choose to terminate
				// the application if all brokers are down.
				fmt.Fprintf(os.Stderr, "%% Error: %v: %v\n", currentEvent.Code(), currentEvent)
				if currentEvent.Code() == kafka.ErrAllBrokersDown {
					run = false
				}
			case nil:
				fmt.Printf("No event %v\n", currentEvent)
				// delay with jitter to prevent synchronization of Poll() calls across consumer instances
				delay := time.Duration(backoffCounter * 10) * time.Millisecond + time.Duration(rand.Intn(100)) * time.Millisecond
				time.Sleep(delay)

				if delay > 2 * time.Minute {
					continue
				} else {
					backoffCounter = backoffCounter * 2 // exponential backoff
				}
			default:
				fmt.Printf("Ignored %v\n", currentEvent)
			}
		}
	}

}
