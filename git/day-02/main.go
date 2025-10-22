package main

import (
	"fmt"
	"log"
	"net/http"
)

func index(w http.ResponseWriter, r *http.Request) {

	w.Header().Set("Content-Type", "text/plain")
	fmt.Fprintf(w, "Example Application - 3.0")
}

// checkSanity makes simples initialization checks
func checkSanity() {
	// 1 + 1 should be equal to 2
	log.Println("Running sanity check...")
	
	if 1 + 1 != 2 {
		log.Fatal("FATAL ERROR: Fail in sanity check! 1 + 1 is not equal to 2.")
		// log.Fatal calls os.Exit(1)
	}
	
	log.Println("Sanity check finished with success.")
}

func main() {
	// 1. Runs sanity check before server initialization
	checkSanity()

	http.HandleFunc("/", index)
	log.Fatal(http.ListenAndServe("0.0.0.0:5000", nil))
}