// Example function-based Apache Kafka producer
package main

import (
	"fmt"
	"github.com/confluentinc/confluent-kafka-go/kafka"
	"os"
	"strconv"
	"sync"
	"time"
)

func produceMessages(wg *sync.WaitGroup, id int, p *kafka.Producer, topic string, key string, messageSet []string, deliveryChan chan kafka.Event) {
	defer wg.Done()

	for i, message := range messageSet {

		p.Produce(
			&kafka.Message{
				TopicPartition: kafka.TopicPartition{Topic: &topic, Partition: kafka.PartitionAny},
				Key:            []byte(key),
				Value:          []byte(message),
				Headers:        []kafka.Header{
					{Key: "messageSet_index", Value: []byte(strconv.Itoa(i))},
					{Key: "worker_id", Value: []byte(strconv.Itoa(id))},
				},
			},
			deliveryChan)

			event := <-deliveryChan

			if event != nil {
				switch ev := event.(type) {
					case *kafka.Message:
						if ev.TopicPartition.Error != nil {
							fmt.Printf("Message delivery failed: %v\n", ev.TopicPartition)
						} else {
							fmt.Printf("Message delivered to topic=%s [%d] at offset %v\n", *ev.TopicPartition.Topic, ev.TopicPartition.Partition, ev.TopicPartition.Offset)
						}
					default:
						fmt.Printf("Non-message Event: %v\n", ev)
				}			
			} else {
				fmt.Printf("ERROR: event is nil, worker_id [%d]\n", id)
				time.Sleep(100 * time.Millisecond)
				os.Exit(1)
			}
		
	}

}

func main() {

	if len(os.Args) < 3 {
		fmt.Fprintf(os.Stderr, "Usage: %s <broker> <topic> <options>\n",
			os.Args[0])
		os.Exit(1)
	}

	broker := os.Args[1]
	topic := os.Args[2]
	loop := false
	if len(os.Args) > 3 {
		if os.Args[3] == "loop" {
			loop = true
		}
	}

	producer, err := kafka.NewProducer(&kafka.ConfigMap{"bootstrap.servers": broker})

	if err != nil {
		fmt.Printf("Failed to create producer: %s\n", err)
		os.Exit(1)
	}

	fmt.Printf("Created Producer %v\n", producer)

	// Optional delivery channel, if not specified the Producer object's
	// .Events channel is used.

	reportChans := make(map[int]chan kafka.Event)
	
	defer func() {
		for _, ch := range reportChans {
			if ch != nil {
				close(ch)
			}
		}
	}()

	words := []string{"apple", "orange", "mango", "durian", "kiwi", "grape", "cherry", "pear", "peach", "plum"}
	messageSetMap := map[string][]string{
		"keyOne": words,
		"keyTwo": words,
		"keyThree": words,
		"keyFour": words,
		"keyFive": words,
	}

	var wg sync.WaitGroup
	//defer wg.Wait()

	for {
		i := 0
		for keyName, messageSet := range messageSetMap {
			fmt.Printf("Main: Starting worker %d for set %s\n", i, keyName)
			
			// init channel
			reportChans[i] = make(chan kafka.Event)
			wg.Add(1)
			go produceMessages(&wg, i, producer, topic, keyName, messageSet, reportChans[i])
			
			i = i + 1
		}
		wg.Wait()

		if !loop {
			break
		}
	}

	producer.Flush(15 * 1000)
}
