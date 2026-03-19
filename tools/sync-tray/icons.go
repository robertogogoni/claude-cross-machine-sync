package main

// Tray icons as embedded PNG byte arrays
// Generated from simple 22x22 icons suitable for system tray

// iconSynced is a green circle with checkmark (all synced)
var iconSynced = generateIcon(0x4c, 0xaf, 0x50) // Material Green 500

// iconSyncing is a blue circle with arrows (sync in progress)
var iconSyncing = generateIcon(0x21, 0x96, 0xf3) // Material Blue 500

// iconError is a red circle with X (daemon not running)
var iconError = generateIcon(0xf4, 0x43, 0x36) // Material Red 500

// generateIcon creates a minimal 22x22 PNG with a colored circle
// This is a programmatic icon generator so we don't need external files
func generateIcon(r, g, b byte) []byte {
	// 22x22 RGBA PNG
	const size = 22
	const channels = 4

	// PNG header
	png := []byte{
		0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, // PNG signature
	}

	// IHDR chunk
	ihdr := []byte{
		0x00, 0x00, 0x00, 0x0d, // length: 13
		0x49, 0x48, 0x44, 0x52, // "IHDR"
		0x00, 0x00, 0x00, size, // width
		0x00, 0x00, 0x00, size, // height
		0x08,       // bit depth: 8
		0x06,       // color type: RGBA
		0x00, 0x00, 0x00, // compression, filter, interlace
	}
	ihdr = append(ihdr, crc32Bytes(ihdr[4:])...)
	png = append(png, ihdr...)

	// IDAT chunk: raw pixel data with zlib
	var rawData []byte
	cx, cy := float64(size)/2, float64(size)/2
	radius := float64(size)/2 - 1

	for y := 0; y < size; y++ {
		rawData = append(rawData, 0x00) // filter: none
		for x := 0; x < size; x++ {
			dx := float64(x) - cx
			dy := float64(y) - cy
			dist := dx*dx + dy*dy

			if dist <= radius*radius {
				// Inside circle: use color with slight edge AA
				edgeDist := radius*radius - dist
				alpha := byte(0xff)
				if edgeDist < radius*2 {
					alpha = byte(float64(0xff) * edgeDist / (radius * 2))
					if alpha < 0x40 {
						alpha = 0x40
					}
				}
				rawData = append(rawData, r, g, b, alpha)
			} else {
				rawData = append(rawData, 0, 0, 0, 0) // transparent
			}
		}
	}

	// Compress with zlib (minimal: stored blocks)
	compressed := zlibStore(rawData)

	idat := make([]byte, 4)
	idat[0] = byte(len(compressed) >> 24)
	idat[1] = byte(len(compressed) >> 16)
	idat[2] = byte(len(compressed) >> 8)
	idat[3] = byte(len(compressed))
	idat = append(idat, []byte("IDAT")...)
	idat = append(idat, compressed...)
	idat = append(idat, crc32Bytes(idat[4:])...)
	png = append(png, idat...)

	// IEND chunk
	iend := []byte{
		0x00, 0x00, 0x00, 0x00,
		0x49, 0x45, 0x4e, 0x44,
	}
	iend = append(iend, crc32Bytes(iend[4:])...)
	png = append(png, iend...)

	return png
}

// zlibStore wraps data in a zlib stored (uncompressed) format
func zlibStore(data []byte) []byte {
	var out []byte
	// Zlib header: CM=8, CINFO=7, FCHECK adjusted
	out = append(out, 0x78, 0x01)

	// Split into 65535-byte blocks
	for len(data) > 0 {
		blockSize := len(data)
		if blockSize > 65535 {
			blockSize = 65535
		}
		last := byte(0x00)
		if blockSize == len(data) {
			last = 0x01
		}
		out = append(out, last)
		out = append(out, byte(blockSize), byte(blockSize>>8))
		out = append(out, byte(^blockSize&0xff), byte((^blockSize>>8)&0xff))
		out = append(out, data[:blockSize]...)
		data = data[blockSize:]
	}

	// Adler32 checksum
	a32 := adler32(out[2:]) // skip zlib header
	out = append(out, byte(a32>>24), byte(a32>>16), byte(a32>>8), byte(a32))

	return out
}

func adler32(data []byte) uint32 {
	var a, b uint32 = 1, 0
	for _, d := range data {
		a = (a + uint32(d)) % 65521
		b = (b + a) % 65521
	}
	return (b << 16) | a
}

// CRC32 for PNG chunks
func crc32Bytes(data []byte) []byte {
	crc := crc32Compute(data)
	return []byte{byte(crc >> 24), byte(crc >> 16), byte(crc >> 8), byte(crc)}
}

func crc32Compute(data []byte) uint32 {
	var crc uint32 = 0xffffffff
	for _, b := range data {
		crc ^= uint32(b)
		for i := 0; i < 8; i++ {
			if crc&1 != 0 {
				crc = (crc >> 1) ^ 0xedb88320
			} else {
				crc >>= 1
			}
		}
	}
	return crc ^ 0xffffffff
}
