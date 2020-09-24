package main

import (
	"io/ioutil"
	"strconv"
	"strings"
)

func main() {
	var assetsExport strings.Builder

	assetsExport.Write([]byte("//nolint // This is generated code\n"))
	assetsExport.Write([]byte("package assets\n\n"))

	var assetsGenerated strings.Builder
	// As of this writing the assets take up around 5 * 90k bytes on disk.
	// After converting to source code, ech byte will be around 5 more bytes on
	// average, ("128, ").
	assetsGenerated.Grow(5 * 90_000 * 5)

	assetsGenerated.Write([]byte("//nolint "))
	assetsGenerated.Write([]byte("// This is generated code, and besides reading this file slows down the linting.\n\n"))
	assetsGenerated.Write([]byte("// +build !codeanalysis\n\n"))
	assetsGenerated.Write([]byte("package assets\n\n"))
	assetsGenerated.Write([]byte("func init() {\n"))

	files := files{
		generated: &assetsGenerated,
		export:    &assetsExport,
	}

	appendFileAsByteArray(Spec{files: files, fileName: "../assets/spritesheet.png", arrayName: "Spritesheet"})

	appendFileAsByteArray(Spec{files: files, fileName: "../assets/hit1.wav", arrayName: "Hit1"})
	appendFileAsByteArray(Spec{files: files, fileName: "../assets/hit2.wav", arrayName: "Hit2"})
	appendFileAsByteArray(Spec{files: files, fileName: "../assets/newLevel.wav", arrayName: "NewLevel"})
	appendFileAsByteArray(Spec{files: files, fileName: "../assets/spell.wav", arrayName: "Spell"})
	appendFileAsByteArray(Spec{files: files, fileName: "../assets/treasure.wav", arrayName: "Treasure"})

	appendFileAsByteArray(Spec{
		files:    files,
		fileName: "../assets/fonts/Courier Prime Sans.ttf", arrayName: "Font",
	})
	appendFileAsByteArray(Spec{files: files, fileName: "../assets/fonts/LICENSE.md", arrayName: "FontLicense"})

	assetsGenerated.Write([]byte("}\n"))

	err := ioutil.WriteFile("../assets/assets.go", []byte(assetsExport.String()), 0600)
	if err != nil {
		panic(err)
	}

	err = ioutil.WriteFile("../assets/generated.go", []byte(assetsGenerated.String()), 0600)
	if err != nil {
		panic(err)
	}
}

type files struct {
	generated *strings.Builder
	export    *strings.Builder
}

type Spec struct {
	files     files
	fileName  string
	arrayName string
}

func appendFileAsByteArray(spec Spec) {
	export := spec.files.export
	fileData, err := ioutil.ReadFile(spec.fileName)
	if err != nil {
		panic(err)
	}

	export.Write([]byte("var "))
	export.Write([]byte(spec.arrayName))
	export.Write([]byte(" []byte\n"))

	generated := spec.files.generated

	generated.Write([]byte("\t"))
	generated.Write([]byte(spec.arrayName))
	generated.Write([]byte(" = []byte{"))

	sep := ""

	for _, v := range fileData {
		generated.Write([]byte(sep))
		generated.Write([]byte(strconv.Itoa(int(v))))
		sep = ", "
	}

	generated.Write([]byte("}\n"))
}
