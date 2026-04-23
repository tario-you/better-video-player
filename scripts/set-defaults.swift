import CoreServices
import UniformTypeIdentifiers

let bundleIdentifier = "computer.moonshot.better-video-player" as CFString

let filenameExtensions = [
    "3g2",
    "3gp",
    "asf",
    "avi",
    "divx",
    "flv",
    "m2t",
    "m2ts",
    "m2v",
    "m4v",
    "mkv",
    "mov",
    "mp4",
    "mpe",
    "mpeg",
    "mpg",
    "mts",
    "ogm",
    "ogv",
    "rm",
    "rmvb",
    "ts",
    "vob",
    "webm",
    "wmv"
]

var contentTypes = Set([
    "public.movie",
    "public.video",
    "public.mpeg",
    "public.mpeg-2-video",
    "public.mpeg-4",
    "com.apple.quicktime-movie",
    "org.matroska.mkv",
    "org.webmproject.webm",
    "public.avi",
    "com.microsoft.windows-media-wmv",
    "com.adobe.flash-video"
])

for filenameExtension in filenameExtensions {
    if let type = UTType(filenameExtension: filenameExtension) {
        contentTypes.insert(type.identifier)
    }
}

var failures: [String] = []

for contentType in contentTypes.sorted() {
    let status = LSSetDefaultRoleHandlerForContentType(
        contentType as CFString,
        .all,
        bundleIdentifier
    )

    if status != noErr {
        failures.append("\(contentType): \(status)")
    }
}

if failures.isEmpty {
    print("Registered \(contentTypes.count) video content types for \(bundleIdentifier).")
} else {
    fputs("Failed to register some content types:\n\(failures.joined(separator: "\n"))\n", stderr)
    exit(1)
}
