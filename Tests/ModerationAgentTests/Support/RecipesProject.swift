import Foundation

/// An app project as `granite` and Granite's template make them: objectVersion 77, synchronized folders (Shared, iOS,
/// macOS), an iOS and a macOS app target, and a local package already linked (RecipeKit, where the template links
/// Granite). Its macOS target is at 13.0, as the template's is, so a link must raise it.
enum RecipesProject {
    static let name = "Recipes.xcodeproj"

    static let pbxproj = #"""
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 77;
	objects = {

/* Begin PBXBuildFile section */
		110000000000000000000001 /* RecipeKit in Frameworks */ = {isa = PBXBuildFile; productRef = 120000000000000000000001 /* RecipeKit */; };
		110000000000000000000002 /* RecipeKit in Frameworks */ = {isa = PBXBuildFile; productRef = 120000000000000000000002 /* RecipeKit */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		130000000000000000000001 /* Recipes.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Recipes.app; sourceTree = BUILT_PRODUCTS_DIR; };
		130000000000000000000002 /* Recipes.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Recipes.app; sourceTree = BUILT_PRODUCTS_DIR; };
/* End PBXFileReference section */

/* Begin PBXFileSystemSynchronizedRootGroup section */
		140000000000000000000001 /* Shared */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			path = Shared;
			sourceTree = "<group>";
		};
		140000000000000000000002 /* iOS */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			path = iOS;
			sourceTree = "<group>";
		};
		140000000000000000000003 /* macOS */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			path = macOS;
			sourceTree = "<group>";
		};
/* End PBXFileSystemSynchronizedRootGroup section */

/* Begin PBXFrameworksBuildPhase section */
		150000000000000000000001 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				110000000000000000000001 /* RecipeKit in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		150000000000000000000002 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				110000000000000000000002 /* RecipeKit in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		160000000000000000000001 = {
			isa = PBXGroup;
			children = (
				140000000000000000000001 /* Shared */,
				140000000000000000000002 /* iOS */,
				140000000000000000000003 /* macOS */,
				160000000000000000000002 /* Products */,
			);
			sourceTree = "<group>";
		};
		160000000000000000000002 /* Products */ = {
			isa = PBXGroup;
			children = (
				130000000000000000000001 /* Recipes.app */,
				130000000000000000000002 /* Recipes.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		170000000000000000000001 /* Recipes-iOS */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 180000000000000000000002 /* Build configuration list for PBXNativeTarget "Recipes-iOS" */;
			buildPhases = (
				190000000000000000000001 /* Sources */,
				150000000000000000000001 /* Frameworks */,
				1A0000000000000000000001 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			fileSystemSynchronizedGroups = (
				140000000000000000000001 /* Shared */,
				140000000000000000000002 /* iOS */,
			);
			name = Recipes-iOS;
			packageProductDependencies = (
				120000000000000000000001 /* RecipeKit */,
			);
			productName = Recipes;
			productReference = 130000000000000000000001 /* Recipes.app */;
			productType = "com.apple.product-type.application";
		};
		170000000000000000000002 /* Recipes-macOS */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 180000000000000000000003 /* Build configuration list for PBXNativeTarget "Recipes-macOS" */;
			buildPhases = (
				190000000000000000000002 /* Sources */,
				150000000000000000000002 /* Frameworks */,
				1A0000000000000000000002 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			fileSystemSynchronizedGroups = (
				140000000000000000000001 /* Shared */,
				140000000000000000000003 /* macOS */,
			);
			name = Recipes-macOS;
			packageProductDependencies = (
				120000000000000000000002 /* RecipeKit */,
			);
			productName = Recipes;
			productReference = 130000000000000000000002 /* Recipes.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		1B0000000000000000000001 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 2660;
				LastUpgradeCheck = 2660;
				TargetAttributes = {
					170000000000000000000001 = {
						CreatedOnToolsVersion = 26.0;
					};
					170000000000000000000002 = {
						CreatedOnToolsVersion = 26.0;
					};
				};
			};
			buildConfigurationList = 180000000000000000000001 /* Build configuration list for PBXProject "Recipes" */;
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = 160000000000000000000001;
			minimizedProjectReferenceProxies = 1;
			packageReferences = (
				1C0000000000000000000001 /* XCLocalSwiftPackageReference "RecipeKit" */,
			);
			preferredProjectObjectVersion = 77;
			productRefGroup = 160000000000000000000002 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				170000000000000000000001 /* Recipes-iOS */,
				170000000000000000000002 /* Recipes-macOS */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		1A0000000000000000000001 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		1A0000000000000000000002 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		190000000000000000000001 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		190000000000000000000002 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		1D0000000000000000000001 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				DEVELOPMENT_TEAM = "";
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = auto;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		1D0000000000000000000002 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				DEVELOPMENT_TEAM = "";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = auto;
				SWIFT_COMPILATION_MODE = wholemodule;
			};
			name = Release;
		};
		1D0000000000000000000003 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "Recipes";
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.productivity";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.recipes;
				PRODUCT_NAME = Recipes;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		1D0000000000000000000004 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "Recipes";
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.productivity";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.recipes;
				PRODUCT_NAME = Recipes;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		1D0000000000000000000005 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_APP_SANDBOX = YES;
				ENABLE_HARDENED_RUNTIME = YES;
				ENABLE_PREVIEWS = YES;
				ENABLE_USER_SELECTED_FILES = readonly;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "Recipes";
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.productivity";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.recipes;
				PRODUCT_NAME = Recipes;
				SDKROOT = macosx;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
			};
			name = Debug;
		};
		1D0000000000000000000006 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_APP_SANDBOX = YES;
				ENABLE_HARDENED_RUNTIME = YES;
				ENABLE_PREVIEWS = YES;
				ENABLE_USER_SELECTED_FILES = readonly;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "Recipes";
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.productivity";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.recipes;
				PRODUCT_NAME = Recipes;
				SDKROOT = macosx;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		180000000000000000000001 /* Build configuration list for PBXProject "Recipes" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				1D0000000000000000000001 /* Debug */,
				1D0000000000000000000002 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		180000000000000000000002 /* Build configuration list for PBXNativeTarget "Recipes-iOS" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				1D0000000000000000000003 /* Debug */,
				1D0000000000000000000004 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		180000000000000000000003 /* Build configuration list for PBXNativeTarget "Recipes-macOS" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				1D0000000000000000000005 /* Debug */,
				1D0000000000000000000006 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */

/* Begin XCLocalSwiftPackageReference section */
		1C0000000000000000000001 /* XCLocalSwiftPackageReference "RecipeKit" */ = {
			isa = XCLocalSwiftPackageReference;
			relativePath = "Packages/RecipeKit";
		};
/* End XCLocalSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
		120000000000000000000001 /* RecipeKit */ = {
			isa = XCSwiftPackageProductDependency;
			productName = RecipeKit;
		};
		120000000000000000000002 /* RecipeKit */ = {
			isa = XCSwiftPackageProductDependency;
			productName = RecipeKit;
		};
/* End XCSwiftPackageProductDependency section */
	};
	rootObject = 1B0000000000000000000001 /* Project object */;
}
"""#

    /// A shared scheme for one platform's app target.
    static func scheme(_ platform: String, target: String) -> String {
        #"""
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2660"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES"
      buildArchitectures = "Automatic">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{{id}}"
               BuildableName = "Recipes.app"
               BlueprintName = "Recipes-{{platform}}"
               ReferencedContainer = "container:Recipes.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{{id}}"
            BuildableName = "Recipes.app"
            BlueprintName = "Recipes-{{platform}}"
            ReferencedContainer = "container:Recipes.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{{id}}"
            BuildableName = "Recipes.app"
            BlueprintName = "Recipes-{{platform}}"
            ReferencedContainer = "container:Recipes.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""#.replacingOccurrences(of: "{{platform}}", with: platform).replacingOccurrences(of: "{{id}}", with: target)
    }

    /// The project, its folders, its schemes and its local package, written into `folder`; `app` is Shared/App.swift.
    static func write(into folder: URL, app: String = plainApp) throws {
        let files: [(String, String)] = [
            ("Recipes.xcodeproj/project.pbxproj", pbxproj),
            ("Recipes.xcodeproj/xcshareddata/xcschemes/Recipes-iOS.xcscheme", scheme("iOS", target: "170000000000000000000001")),
            ("Recipes.xcodeproj/xcshareddata/xcschemes/Recipes-macOS.xcscheme", scheme("macOS", target: "170000000000000000000002")),
            ("Shared/App.swift", app),
            ("iOS/Platform.swift", "enum Platform { static let name = \"iOS\" }\n"),
            ("macOS/Platform.swift", "enum Platform { static let name = \"macOS\" }\n"),
            ("Packages/RecipeKit/Package.swift", recipeKitManifest),
            ("Packages/RecipeKit/Sources/RecipeKit/Recipe.swift", recipeKitSource),
        ]
        for (path, text) in files {
            let url = folder.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try text.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    static let plainApp = """
        import RecipeKit
        import SwiftUI

        @main
        struct RecipesApp: App {
            var body: some Scene {
                WindowGroup {
                    Text(Recipe(id: "1", title: "Soup", photo: "").title)
                }
            }
        }

        """

    /// The app once the package is linked: every part of it used as an app would use it.
    static func moderatedApp(_ module: String) -> String {
        """
        import \(module)
        import RecipeKit
        import SwiftUI

        @main
        struct RecipesApp: App {
            var body: some Scene {
                WindowGroup {
                    NavigationStack {
                        RecipeList()
                    }
                }
            }
        }

        struct RecipeList: View {
            @State private var policy = ModerationPolicy.standard
            @State private var moderator = Moderator(imageSafety: CoreMLImageSafety(source: .bundled("FoodPhotoSafety")))
            @State private var verdicts: [String: Verdict] = [:]
            private let recipes = [Recipe(id: "1", title: "Spoiler: the secret is butter", photo: "https://example.com/soup.jpg")]

            var body: some View {
                List {
                    ForEach(recipes.filter { verdicts[$0.id]?.hides != true }) { recipe in
                        Text(recipe.title)
                            .censorOverlay(verdicts[recipe.id] ?? .allow)
                    }
                    NavigationLink("Filtered words") {
                        KeywordListEditor(policy: $policy, fields: [KeywordField("title", title: "Titles")])
                    }
                }
                .navigationTitle("Recipes")
                .task(id: policy) {
                    await moderator.update(policy)
                    let contents = recipes.map { recipe in
                        ModeratedContent(id: recipe.id, text: ["title": recipe.title], images: URL(string: recipe.photo).map { [.url($0)] } ?? [])
                    }
                    verdicts = await moderator.judge(contents)
                }
            }
        }

        """
    }

    static let recipeKitManifest = """
        // swift-tools-version:6.0
        import PackageDescription

        let package = Package(
            name: "RecipeKit",
            platforms: [.iOS(.v17), .macOS(.v13)],
            products: [.library(name: "RecipeKit", targets: ["RecipeKit"])],
            targets: [.target(name: "RecipeKit")]
        )

        """

    static let recipeKitSource = """
        /// A dish someone saved.
        public struct Recipe: Identifiable, Sendable {
            public let id: String
            public let title: String
            public let photo: String

            public init(id: String, title: String, photo: String) {
                self.id = id
                self.title = title
                self.photo = photo
            }
        }

        """
}
