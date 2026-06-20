import Vision
import Foundation
import AppKit

guard CommandLine.arguments.count > 1 else { FileHandle.standardError.write("usage: ocr <image>\n".data(using:.utf8)!); exit(2) }
let path = CommandLine.arguments[1]
guard let img = NSImage(contentsOfFile: path),
      let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
  FileHandle.standardError.write("cannot load image\n".data(using:.utf8)!); exit(1)
}
var out: [String] = []
let req = VNRecognizeTextRequest { request, _ in
  for case let obs as VNRecognizedTextObservation in (request.results ?? []) {
    if let t = obs.topCandidates(1).first?.string { out.append(t) }
  }
}
req.recognitionLevel = .accurate
req.recognitionLanguages = ["zh-Hans","zh-Hant","en-US"]
req.usesLanguageCorrection = true
try? VNImageRequestHandler(cgImage: cg, options: [:]).perform([req])
print(out.joined(separator: "\n"))
