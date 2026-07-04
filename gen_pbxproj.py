#!/usr/bin/env python3
"""Generate a valid Xcode pbxproj for BiliLite — no hand-written errors."""

L = []  # output lines

def add(s=""): L.append(s)

# All source files: (filename, parent_group_key)
FILES = [
    # App
    ("BiliLiteApp.swift", "App"),
    # Models
    ("APIResponse.swift", "Models"),
    ("Video.swift", "Models"),
    ("VideoDetail.swift", "Models"),
    ("VideoStream.swift", "Models"),
    ("Comment.swift", "Models"),
    ("SearchResult.swift", "Models"),
    ("UserProfile.swift", "Models"),
    # Services
    ("BiliAPIClient.swift", "Services"),
    ("WBISigner.swift", "Services"),
    ("DeviceIdentity.swift", "Services"),
    ("ImageCache.swift", "Services"),
    # ViewModels
    ("HomeViewModel.swift", "ViewModels"),
    ("VideoDetailViewModel.swift", "ViewModels"),
    ("PlayerViewModel.swift", "ViewModels"),
    ("SearchViewModel.swift", "ViewModels"),
    ("CommentViewModel.swift", "ViewModels"),
    # Views — MainTabView is directly in Views/
    ("MainTabView.swift", "Views"),
    ("HomeView.swift", "Views/Home"),
    ("VideoCard.swift", "Views/Home"),
    ("VideoDetailView.swift", "Views/Detail"),
    ("CommentListView.swift", "Views/Detail"),
    ("VideoPlayerView.swift", "Views/Player"),
    ("PlayerOverlay.swift", "Views/Player"),
    ("SearchView.swift", "Views/Search"),
    ("CachedAsyncImage.swift", "Views/Common"),
    ("LoadingView.swift", "Views/Common"),
    ("ErrorBanner.swift", "Views/Common"),
    # Utils
    ("Constants.swift", "Utils"),
    ("ViewExtensions.swift", "Utils"),
    # Resources
    ("Assets.xcassets", "Resources"),
]

def fid(n): return f"{n:024X}"  # 24-digit hex

# Generate IDs for each file
BUILD = {}   # name -> PBXBuildFile id
FILEREF = {} # name -> PBXFileReference id
for i, (name, _) in enumerate(FILES):
    BUILD[name] = fid(1000001 + i)
    FILEREF[name] = fid(2000001 + i)

PRODUCT_REF = fid(2999999)

# ----- PBXBuildFile -----
add("/* Begin PBXBuildFile section */")
for name, grp in FILES:
    ref = FILEREF[name]
    if name == "Assets.xcassets":
        add(f"\t\t{BUILD[name]} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {name} */; }};")
    else:
        add(f"\t\t{BUILD[name]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {name} */; }};")
add("/* End PBXBuildFile section */")
add("")

# ----- PBXFileReference -----
add("/* Begin PBXFileReference section */")
for name, grp in FILES:
    ref = FILEREF[name]
    if name == "Assets.xcassets":
        add(f"\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = {name}; sourceTree = \"<group>\"; }};")
    else:
        add(f"\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};")
add(f"\t\t{PRODUCT_REF} /* BiliLite.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = BiliLite.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
add("/* End PBXFileReference section */")
add("")

# ----- PBXFrameworksBuildPhase -----
FWB = fid(3000001)
add("/* Begin PBXFrameworksBuildPhase section */")
add(f"\t\t{FWB} /* Frameworks */ = {{")
add("\t\t\tisa = PBXFrameworksBuildPhase;")
add("\t\t\tbuildActionMask = 2147483647;")
add("\t\t\tfiles = ();")
add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
add("\t\t};")
add("/* End PBXFrameworksBuildPhase section */")
add("")

# ----- PBXGroup -----
GROUP = {}  # key -> group id
for k in ["ROOT","App","Models","Services","ViewModels","Views","Views/Home",
           "Views/Detail","Views/Player","Views/Search","Views/Common","Utils","Resources","Products"]:
    GROUP[k] = fid(4000000 + len(GROUP))

def group(id_, children_refs, name="", path=""):
    add(f"\t\t{id_} /* {name or path} */ = {{")
    add("\t\t\tisa = PBXGroup;")
    add("\t\t\tchildren = (")
    for c in children_refs:
        add(f"\t\t\t\t{c},")
    add("\t\t\t);")
    if name:
        add(f"\t\t\tname = {name};")
    if path:
        add(f"\t\t\tpath = {path};")
    add("\t\t\tsourceTree = \"<group>\";")
    add("\t\t};")

add("/* Begin PBXGroup section */")

# Leaf groups
for grp_name, group_id in [
    ("App", GROUP["App"]),
    ("Models", GROUP["Models"]),
    ("Services", GROUP["Services"]),
    ("ViewModels", GROUP["ViewModels"]),
    ("Utils", GROUP["Utils"]),
]:
    refs = [FILEREF[n] for n, g in FILES if g == grp_name]
    group(group_id, refs, path=grp_name)

# Home
refs_home = [FILEREF[n] for n, g in FILES if g == "Views/Home"]
group(GROUP["Views/Home"], refs_home, path="Home")

# Detail
refs_detail = [FILEREF[n] for n, g in FILES if g == "Views/Detail"]
group(GROUP["Views/Detail"], refs_detail, path="Detail")

# Player
refs_player = [FILEREF[n] for n, g in FILES if g == "Views/Player"]
group(GROUP["Views/Player"], refs_player, path="Player")

# Search
refs_search = [FILEREF[n] for n, g in FILES if g == "Views/Search"]
group(GROUP["Views/Search"], refs_search, path="Search")

# Common
refs_common = [FILEREF[n] for n, g in FILES if g == "Views/Common"]
group(GROUP["Views/Common"], refs_common, path="Common")

# Views (parent) — MainTabView + sub-groups
views_children = []
for n, g in FILES:
    if g == "Views":
        views_children.append(FILEREF[n])
views_children += [
    GROUP["Views/Home"], GROUP["Views/Detail"], GROUP["Views/Player"],
    GROUP["Views/Search"], GROUP["Views/Common"]
]
group(GROUP["Views"], views_children, name="Views", path="Views")

# Resources
group(GROUP["Resources"], [FILEREF["Assets.xcassets"]], path="Resources")

# Products
group(GROUP["Products"], [PRODUCT_REF], name="Products")

# Root
root_children = [
    GROUP["App"], GROUP["Models"], GROUP["Services"], GROUP["ViewModels"],
    GROUP["Views"], GROUP["Utils"], GROUP["Resources"], GROUP["Products"]
]
group(GROUP["ROOT"], root_children)

add("/* End PBXGroup section */")
add("")

# ----- PBXNativeTarget -----
TGT = fid(5000001)
add("/* Begin PBXNativeTarget section */")
add(f"\t\t{TGT} /* BiliLite */ = {{")
add("\t\t\tisa = PBXNativeTarget;")
add(f"\t\t\tbuildConfigurationList = {fid(8000002)} /* BCL target */;")
add("\t\t\tbuildPhases = (")
add(f"\t\t\t\t{fid(6000001)} /* Sources */,")
add(f"\t\t\t\t{FWB} /* Frameworks */,")
add(f"\t\t\t\t{fid(7000001)} /* Resources */,")
add("\t\t\t);")
add("\t\t\tbuildRules = ();")
add("\t\t\tdependencies = ();")
add("\t\t\tname = BiliLite;")
add("\t\t\tproductName = BiliLite;")
add(f"\t\t\tproductReference = {PRODUCT_REF};")
add("\t\t\tproductType = \"com.apple.product-type.application\";")
add("\t\t};")
add("/* End PBXNativeTarget section */")
add("")

# ----- PBXProject -----
PRJ = fid(9000001)
add("/* Begin PBXProject section */")
add(f"\t\t{PRJ} /* Project object */ = {{")
add("\t\t\tisa = PBXProject;")
add("\t\t\tattributes = {")
add("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
add("\t\t\t\tLastSwiftUpdateCheck = 1520;")
add("\t\t\t\tLastUpgradeCheck = 1520;")
add("\t\t\t\tTargetAttributes = {")
add(f"\t\t\t\t\t{TGT} = {{CreatedOnToolsVersion = 15.2; }};")
add("\t\t\t\t};")
add("\t\t\t};")
add(f"\t\t\tbuildConfigurationList = {fid(8000001)} /* BCL project */;")
add("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
add("\t\t\tdevelopmentRegion = \"zh-Hans\";")
add("\t\t\thasScannedForEncodings = 0;")
add("\t\t\tknownRegions = (en, \"zh-Hans\", Base);")
add(f"\t\t\tmainGroup = {GROUP['ROOT']};")
add(f"\t\t\tproductRefGroup = {GROUP['Products']};")
add("\t\t\tprojectDirPath = \"\";")
add("\t\t\tprojectRoot = \"\";")
add("\t\t\ttargets = (")
add(f"\t\t\t\t{TGT} /* BiliLite */,")
add("\t\t\t);")
add("\t\t};")
add("/* End PBXProject section */")
add("")

# ----- PBXResourcesBuildPhase -----
RES = fid(7000001)
add("/* Begin PBXResourcesBuildPhase section */")
add(f"\t\t{RES} /* Resources */ = {{")
add("\t\t\tisa = PBXResourcesBuildPhase;")
add("\t\t\tbuildActionMask = 2147483647;")
add("\t\t\tfiles = (")
add(f"\t\t\t\t{BUILD['Assets.xcassets']} /* Assets.xcassets in Resources */,")
add("\t\t\t);")
add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
add("\t\t};")
add("/* End PBXResourcesBuildPhase section */")
add("")

# ----- PBXSourcesBuildPhase -----
SRC = fid(6000001)
add("/* Begin PBXSourcesBuildPhase section */")
add(f"\t\t{SRC} /* Sources */ = {{")
add("\t\t\tisa = PBXSourcesBuildPhase;")
add("\t\t\tbuildActionMask = 2147483647;")
add("\t\t\tfiles = (")
for name, grp in FILES:
    if name != "Assets.xcassets":
        add(f"\t\t\t\t{BUILD[name]} /* {name} in Sources */,")
add("\t\t\t);")
add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
add("\t\t};")
add("/* End PBXSourcesBuildPhase section */")
add("")

# ----- XCBuildConfiguration -----
add("/* Begin XCBuildConfiguration section */")

def cfg(id_, name_, settings):
    add(f"\t\t{id_} /* {name_} */ = {{")
    add("\t\t\tisa = XCBuildConfiguration;")
    add("\t\t\tbuildSettings = {")
    for s in settings:
        add(f"\t\t\t\t{s}")
    add("\t\t\t};")
    add(f"\t\t\tname = {name_};")
    add("\t\t};")

# Project Debug
cfg(fid(11000001), "Debug", [
    "ALWAYS_SEARCH_USER_PATHS = NO;",
    "CLANG_ANALYZER_NONNULL = YES;",
    "CLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";",
    "CLANG_ENABLE_MODULES = YES;",
    "CLANG_ENABLE_OBJC_ARC = YES;",
    "COPY_PHASE_STRIP = NO;",
    "DEBUG_INFORMATION_FORMAT = dwarf;",
    "ENABLE_STRICT_OBJC_MSGSEND = YES;",
    "ENABLE_TESTABILITY = YES;",
    "GCC_DYNAMIC_NO_PIC = NO;",
    "GCC_OPTIMIZATION_LEVEL = 0;",
    "IPHONEOS_DEPLOYMENT_TARGET = 16.0;",
    "MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;",
    "ONLY_ACTIVE_ARCH = YES;",
    "SDKROOT = iphoneos;",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;",
    "SWIFT_OPTIMIZATION_LEVEL = \"-Onone\";",
])

# Project Release
cfg(fid(11000002), "Release", [
    "ALWAYS_SEARCH_USER_PATHS = NO;",
    "CLANG_ANALYZER_NONNULL = YES;",
    "CLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";",
    "CLANG_ENABLE_MODULES = YES;",
    "CLANG_ENABLE_OBJC_ARC = YES;",
    "COPY_PHASE_STRIP = NO;",
    "DEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";",
    "ENABLE_NS_ASSERTIONS = NO;",
    "ENABLE_STRICT_OBJC_MSGSEND = YES;",
    "GCC_OPTIMIZATION_LEVEL = s;",
    "IPHONEOS_DEPLOYMENT_TARGET = 16.0;",
    "MTL_ENABLE_DEBUG_INFO = NO;",
    "SDKROOT = iphoneos;",
    "SWIFT_COMPILATION_MODE = wholemodule;",
    "SWIFT_OPTIMIZATION_LEVEL = \"-O\";",
    "VALIDATE_PRODUCT = YES;",
])

# Target Debug
cfg(fid(11000003), "Debug", [
    "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;",
    "CODE_SIGN_STYLE = Automatic;",
    "CURRENT_PROJECT_VERSION = 1;",
    "INFOPLIST_FILE = \"\";",
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;",
    "INFOPLIST_KEY_UILaunchScreen_Generation = YES;",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;",
    "LD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@executable_path/Frameworks\");",
    "MARKETING_VERSION = 1.0;",
    "PRODUCT_BUNDLE_IDENTIFIER = com.bililite.app;",
    "PRODUCT_NAME = \"$(TARGET_NAME)\";",
    "SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\";",
    "SWIFT_EMIT_LOC_STRINGS = YES;",
    "SWIFT_VERSION = 5.0;",
    "TARGETED_DEVICE_FAMILY = 1;",
])

# Target Release
cfg(fid(11000004), "Release", [
    "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;",
    "CODE_SIGN_STYLE = Automatic;",
    "CURRENT_PROJECT_VERSION = 1;",
    "INFOPLIST_FILE = \"\";",
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;",
    "INFOPLIST_KEY_UILaunchScreen_Generation = YES;",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;",
    "LD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@executable_path/Frameworks\");",
    "MARKETING_VERSION = 1.0;",
    "PRODUCT_BUNDLE_IDENTIFIER = com.bililite.app;",
    "PRODUCT_NAME = \"$(TARGET_NAME)\";",
    "SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\";",
    "SWIFT_EMIT_LOC_STRINGS = YES;",
    "SWIFT_VERSION = 5.0;",
    "TARGETED_DEVICE_FAMILY = 1;",
])

add("/* End XCBuildConfiguration section */")
add("")

# ----- XCConfigurationList -----
add("/* Begin XCConfigurationList section */")

add(f"\t\t{fid(8000002)} /* BCL target */ = {{")
add("\t\t\tisa = XCConfigurationList;")
add("\t\t\tbuildConfigurations = (")
add(f"\t\t\t\t{fid(11000003)} /* Debug */,")
add(f"\t\t\t\t{fid(11000004)} /* Release */,")
add("\t\t\t);")
add("\t\t\tdefaultConfigurationIsVisible = 0;")
add("\t\t\tdefaultConfigurationName = Release;")
add("\t\t};")

add(f"\t\t{fid(8000001)} /* BCL project */ = {{")
add("\t\t\tisa = XCConfigurationList;")
add("\t\t\tbuildConfigurations = (")
add(f"\t\t\t\t{fid(11000001)} /* Debug */,")
add(f"\t\t\t\t{fid(11000002)} /* Release */,")
add("\t\t\t);")
add("\t\t\tdefaultConfigurationIsVisible = 0;")
add("\t\t\tdefaultConfigurationName = Release;")
add("\t\t};")

add("/* End XCConfigurationList section */")
add("")

# ----- Final -----
add("\t};")
add(f"\trootObject = {PRJ} /* Project object */;")
add("}")

# Write
header = "// !$*UTF8*$!\n"
output = header + "\n".join(L) + "\n"
with open("BiliLite.xcodeproj/project.pbxproj", "w", encoding="utf-8", newline="\n") as f:
    f.write(output)
print("pbxproj generated successfully")
print(f"Lines: {len(L)}")
