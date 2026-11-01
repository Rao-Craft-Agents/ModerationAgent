import Foundation

/// A project in the older shape a fresh Xcode app had before synchronized folders: classic groups, an iOS app at
/// 16.0 with a unit-test target, and no package anywhere, so a link must make every section and list it needs.
enum ClassicProject {
    static let pbxproj = #"""
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		A10000000000000000000001 /* ClassicApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20000000000000000000001 /* ClassicApp.swift */; };
		A10000000000000000000002 /* ClassicTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20000000000000000000002 /* ClassicTests.swift */; };
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
		A30000000000000000000001 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = A90000000000000000000001 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = A60000000000000000000001;
			remoteInfo = Classic;
		};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
		A20000000000000000000001 /* ClassicApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ClassicApp.swift; sourceTree = "<group>"; };
		A20000000000000000000002 /* ClassicTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ClassicTests.swift; sourceTree = "<group>"; };
		A20000000000000000000003 /* Classic.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Classic.app; sourceTree = BUILT_PRODUCTS_DIR; };
		A20000000000000000000004 /* ClassicTests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = ClassicTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		A40000000000000000000001 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		A40000000000000000000002 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		A50000000000000000000001 = {
			isa = PBXGroup;
			children = (
				A50000000000000000000002 /* Classic */,
				A50000000000000000000003 /* ClassicTests */,
				A50000000000000000000004 /* Products */,
			);
			sourceTree = "<group>";
		};
		A50000000000000000000002 /* Classic */ = {
			isa = PBXGroup;
			children = (
				A20000000000000000000001 /* ClassicApp.swift */,
			);
			path = Classic;
			sourceTree = "<group>";
		};
		A50000000000000000000003 /* ClassicTests */ = {
			isa = PBXGroup;
			children = (
				A20000000000000000000002 /* ClassicTests.swift */,
			);
			path = ClassicTests;
			sourceTree = "<group>";
		};
		A50000000000000000000004 /* Products */ = {
			isa = PBXGroup;
			children = (
				A20000000000000000000003 /* Classic.app */,
				A20000000000000000000004 /* ClassicTests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		A60000000000000000000001 /* Classic */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = A80000000000000000000002 /* Build configuration list for PBXNativeTarget "Classic" */;
			buildPhases = (
				A70000000000000000000001 /* Sources */,
				A40000000000000000000001 /* Frameworks */,
				A70000000000000000000003 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = Classic;
			productName = Classic;
			productReference = A20000000000000000000003 /* Classic.app */;
			productType = "com.apple.product-type.application";
		};
		A60000000000000000000002 /* ClassicTests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = A80000000000000000000003 /* Build configuration list for PBXNativeTarget "ClassicTests" */;
			buildPhases = (
				A70000000000000000000002 /* Sources */,
				A40000000000000000000002 /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
				AB0000000000000000000001 /* PBXTargetDependency */,
			);
			name = ClassicTests;
			productName = ClassicTests;
			productReference = A20000000000000000000004 /* ClassicTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		A90000000000000000000001 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
			};
			buildConfigurationList = A80000000000000000000001 /* Build configuration list for PBXProject "Classic" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = A50000000000000000000001;
			productRefGroup = A50000000000000000000004 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				A60000000000000000000001 /* Classic */,
				A60000000000000000000002 /* ClassicTests */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		A70000000000000000000003 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		A70000000000000000000001 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				A10000000000000000000001 /* ClassicApp.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		A70000000000000000000002 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				A10000000000000000000002 /* ClassicTests.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		AB0000000000000000000001 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = A60000000000000000000001 /* Classic */;
			targetProxy = A30000000000000000000001 /* PBXContainerItemProxy */;
		};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		AA0000000000000000000001 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		AA0000000000000000000002 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		AA0000000000000000000003 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.Classic;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		AA0000000000000000000004 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.Classic;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
		AA0000000000000000000005 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BUNDLE_LOADER = "$(TEST_HOST)";
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.ClassicTests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/Classic.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Classic";
			};
			name = Debug;
		};
		AA0000000000000000000006 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BUNDLE_LOADER = "$(TEST_HOST)";
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.ClassicTests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/Classic.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Classic";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		A80000000000000000000001 /* Build configuration list for PBXProject "Classic" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AA0000000000000000000001 /* Debug */,
				AA0000000000000000000002 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		A80000000000000000000002 /* Build configuration list for PBXNativeTarget "Classic" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AA0000000000000000000003 /* Debug */,
				AA0000000000000000000004 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		A80000000000000000000003 /* Build configuration list for PBXNativeTarget "ClassicTests" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AA0000000000000000000005 /* Debug */,
				AA0000000000000000000006 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = A90000000000000000000001 /* Project object */;
}
"""#

    /// The same project with its app's Frameworks phase taken out, as a hand-pruned project may have it.
    static var withoutFrameworksPhase: String {
        pbxproj
            .replacingOccurrences(of: "\t\t\t\tA40000000000000000000001 /* Frameworks */,\n", with: "")
            .replacingOccurrences(of: """
                		A40000000000000000000001 /* Frameworks */ = {
                			isa = PBXFrameworksBuildPhase;
                			buildActionMask = 2147483647;
                			files = (
                			);
                			runOnlyForDeploymentPostprocessing = 0;
                		};

                """, with: "")
    }
}
