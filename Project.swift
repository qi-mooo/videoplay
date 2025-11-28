import ProjectDescription

let project = Project(
    name: "Videoplay",
    packages: [],
    targets: [
        .target(
            name: "Videoplay",
            destinations: .iOS,
            product: .app,
            bundleId: "com.example.videoplay",
            infoPlist: .extendingDefault(with: [
                "UILaunchStoryboardName": "LaunchScreen",
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait", "UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"],
                "NSLocalNetworkUsageDescription": "需要访问本地网络以连接 SMB/WebDAV 服务器",
                "NSBonjourServices": ["_smb._tcp", "_webdav._tcp"],
                "CFBundleURLTypes": [
                    [
                        "CFBundleURLName": "com.example.videoplay",
                        "CFBundleURLSchemes": ["videoplay"]
                    ]
                ]
            ]),
            sources: [
                "Sources/**/*.swift",
                "Sources/GPUPixel/*.h",
                "Sources/GPUPixel/*.mm"
            ],
            resources: [
                "sample.mp4",
                "gpupixel_ios_arm64/models/**",
                "gpupixel_ios_arm64/res/**",
                "Resources/Assets.xcassets"
            ],
            headers: .headers(
                public: ["Sources/GPUPixel/GPUPixelWrapper.h"],
                private: [],
                project: []
            ),
            dependencies: [
                .framework(path: "gpupixel_ios_arm64/lib/gpupixel.framework", status: .required),
                .sdk(name: "AVFoundation", type: .framework),
                .sdk(name: "CoreMedia", type: .framework),
                .sdk(name: "CoreVideo", type: .framework),
                .sdk(name: "CoreML", type: .framework),
                .sdk(name: "OpenGLES", type: .framework),
                .sdk(name: "GLKit", type: .framework),
                .sdk(name: "UIKit", type: .framework),
                .sdk(name: "Foundation", type: .framework),
                .sdk(name: "QuartzCore", type: .framework),
                .sdk(name: "CoreGraphics", type: .framework),
                .sdk(name: "Metal", type: .framework)
            ],
            settings: .settings(
                base: [
                    "SWIFT_OBJC_BRIDGING_HEADER": "Sources/GPUPixel/BridgingHeader.h",
                    "FRAMEWORK_SEARCH_PATHS": [
                        "$(PROJECT_DIR)/gpupixel_ios_arm64/lib"
                    ],
                    "HEADER_SEARCH_PATHS": [
                        "$(PROJECT_DIR)/gpupixel_ios_arm64/include"
                    ],
                    "OTHER_LDFLAGS": [
                        "-ObjC",
                        "-lstdc++"
                    ],
                    "LD_RUNPATH_SEARCH_PATHS": [
                        "$(inherited)",
                        "@executable_path/Frameworks"
                    ],
                    "ENABLE_BITCODE": "NO",
                    "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
                    "TARGETED_DEVICE_FAMILY": "1,2",
                    "CODE_SIGN_IDENTITY": "",
                    "CODE_SIGNING_REQUIRED": "NO",
                    "CODE_SIGNING_ALLOWED": "NO"
                ]
            )
        )
    ]
)
