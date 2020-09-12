package main

import (
	"io/ioutil"
	"strconv"
	"strings"
)

func main() {
	var output strings.Builder
	// As of this writing the assets take up around 5 * 90k bytes on disk.
	// After converting to source code, ech byte will be around 5 more bytes on
	// average, ("128, ").
	output.Grow(5 * 90_000 * 5)

	output.Write([]byte("//nolint "))
	output.Write([]byte("// This generated code, and besides reading this file is slowing down the linting.\n"))
	output.Write([]byte("package assets\n\n"))

	appendFileAsByteArray(Spec{output: &output, fileName: "../assets/spritesheet.png", arrayName: "Spritesheet"})

	appendFileAsByteArray(Spec{output: &output, fileName: "../assets/hit1.wav", arrayName: "Hit1"})
	appendFileAsByteArray(Spec{output: &output, fileName: "../assets/hit2.wav", arrayName: "Hit2"})
	appendFileAsByteArray(Spec{output: &output, fileName: "../assets/newLevel.wav", arrayName: "NewLevel"})
	appendFileAsByteArray(Spec{output: &output, fileName: "../assets/spell.wav", arrayName: "Spell"})
	appendFileAsByteArray(Spec{output: &output, fileName: "../assets/treasure.wav", arrayName: "Treasure"})

	appendFileAsByteArray(Spec{
		output:   &output,
		fileName: "../assets/fonts/Courier Prime Sans.ttf", arrayName: "Font",
	})
	appendFileAsByteArray(Spec{output: &output, fileName: "../assets/fonts/LICENSE.md", arrayName: "FontLicense"})

	err := ioutil.WriteFile("../assets/assets.go", []byte(output.String()), 0600)
	if err != nil {
		panic(err)
	}
}

type Spec struct {
	output    *strings.Builder
	fileName  string
	arrayName string
}

func appendFileAsByteArray(spec Spec) {
	output := spec.output
	fileData, err := ioutil.ReadFile(spec.fileName)
	if err != nil {
		panic(err)
	}

	output.Write([]byte("var "))
	output.Write([]byte(spec.arrayName))
	output.Write([]byte(" = []byte{"))

	sep := ""

	for _, v := range fileData {
		output.Write([]byte(sep))
		output.Write([]byte(strconv.Itoa(int(v))))
		sep = ", "
	}

	output.Write([]byte("}\n"))
}
