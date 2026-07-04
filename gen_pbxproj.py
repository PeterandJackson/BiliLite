#!/usr/bin/env python3
"""Generate a valid Xcode pbxproj for ClothingAR."""
import os

FILES = [
    ("AppDelegate.swift", "App"),
    ("SceneDelegate.swift", "App"),
    ("CameraManager.swift", "Core"),
    ("BodyTracker.swift", "Core"),
    ("SkeletonMapper.swift", "Core"),
    ("PersonSegmentation.swift", "Core"),
    ("SceneRenderer.swift", "Core"),
    ("ModelLoader.swift", "Core"),
    ("ModelCalibration.swift", "Core"),
    ("VideoRecorder.swift", "Recording"),
    ("PhotoAlbumSaver.swift", "Recording"),
    ("ARViewController.swift", "UI"),
    ("RecordButton.swift", "UI"),
    ("StatusIndicator.swift", "UI"),
    ("PerformanceMonitor.swift", "Performance"),
    ("QualityManager.swift", "Performance"),
    ("Info.plist", "Resources"),
    ("Assets.xcassets", "Resources"),
]

L = []
def add(s=""): L.append(s)

add("// !$*UTF8*$!"); add("{"); add("\tarchiveVersion = 1;"); add("\tclasses = {};")
add("\tobjectVersion = 56;"); add("\tobjects = {"); add("")

def fid(n): return f"{n:024X}"

BUILD = {}; FILEREF = {}
for i, (name, _) in enumerate(FILES):
    BUILD[name] = fid(1000001 + i)
    FILEREF[name] = fid(2000001 + i)
PRODUCT_REF = fid(2999999)

add("/* Begin PBXBuildFile section */")
for name, grp in FILES:
    ref = FILEREF[name]
    if name == "Assets.xcassets":
        add(f"\t\t{BUILD[name]} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {name} */; }};")
    elif name == "Info.plist": pass
    else:
        add(f"\t\t{BUILD[name]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {name} */; }};")
add("/* End PBXBuildFile section */"); add("")

add("/* Begin PBXFileReference section */")
for name, grp in FILES:
    ref = FILEREF[name]
    if name == "Assets.xcassets":
        add(f"\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = {name}; sourceTree = \"<group>\"; }};")
    elif name == "Info.plist":
        add(f"\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = {name}; sourceTree = \"<group>\"; }};")
    else:
        add(f"\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};")
add(f"\t\t{PRODUCT_REF} /* ClothingAR.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = ClothingAR.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
add("/* End PBXFileReference section */"); add("")

FWB = fid(3000001)
add("/* Begin PBXFrameworksBuildPhase section */")
add(f"\t\t{FWB} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};")
add("/* End PBXFrameworksBuildPhase section */"); add("")

GROUP = {}
for k in ["ROOT","App","Core","Recording","UI","Performance","Resources","Products"]:
    GROUP[k] = fid(4000000 + len(GROUP))

def group(id_, refs, name="", path=""):
    add(f"\t\t{id_} /* {name or path} */ = {{")
    add("\t\t\tisa = PBXGroup;")
    add("\t\t\tchildren = (")
    for c in refs: add(f"\t\t\t\t{c},")
    add("\t\t\t);")
    if name: add(f"\t\t\tname = {name};")
    if path: add(f"\t\t\tpath = {path};")
    add("\t\t\tsourceTree = \"<group>\";")
    add("\t\t};")

add("/* Begin PBXGroup section */")
for gname in ["App","Core","Recording","UI","Performance"]:
    refs = [FILEREF[n] for n, g in FILES if g == gname]
    group(GROUP[gname], refs, path=gname)
group(GROUP["Resources"], [FILEREF["Info.plist"], FILEREF["Assets.xcassets"]], path="Resources")
group(GROUP["Products"], [PRODUCT_REF], name="Products")
root_kids = [GROUP["App"],GROUP["Core"],GROUP["Recording"],GROUP["UI"],GROUP["Performance"],GROUP["Resources"],GROUP["Products"]]
group(GROUP["ROOT"], root_kids)
add("/* End PBXGroup section */"); add("")

TGT = fid(5000001)
add("/* Begin PBXNativeTarget section */")
add(f"\t\t{TGT} /* ClothingAR */ = {{")
add("\t\t\tisa = PBXNativeTarget;")
add(f"\t\t\tbuildConfigurationList = {fid(8000002)} /* BCL */;")
add("\t\t\tbuildPhases = (")
add(f"\t\t\t\t{fid(6000001)} /* Sources */,")
add(f"\t\t\t\t{FWB} /* Frameworks */,")
add(f"\t\t\t\t{fid(7000001)} /* Resources */,")
add("\t\t\t);")
add("\t\t\tbuildRules = ();")
add("\t\t\tdependencies = ();")
add("\t\t\tname = ClothingAR;")
add("\t\t\tproductName = ClothingAR;")
add(f"\t\t\tproductReference = {PRODUCT_REF};")
add("\t\t\tproductType = \"com.apple.product-type.application\";")
add("\t\t};")
add("/* End PBXNativeTarget section */"); add("")

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
add("\t\t\tprojectDirPath = \"ClothingAR\";")
add("\t\t\tprojectRoot = \"\";")
add("\t\t\ttargets = (")
add(f"\t\t\t\t{TGT} /* ClothingAR */,")
add("\t\t\t);")
add("\t\t};")
add("/* End PBXProject section */"); add("")

add("/* Begin PBXResourcesBuildPhase section */")
add(f"\t\t{fid(7000001)} /* Resources */ = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({BUILD['Assets.xcassets']} /* Assets.xcassets in Resources */,); runOnlyForDeploymentPostprocessing = 0; }};")
add("/* End PBXResourcesBuildPhase section */"); add("")

add("/* Begin PBXSourcesBuildPhase section */")
add(f"\t\t{fid(6000001)} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (")
for name, grp in FILES:
    if name not in ("Assets.xcassets", "Info.plist"):
        add(f"\t\t\t\t{BUILD[name]} /* {name} in Sources */,")
add("\t\t\t); runOnlyForDeploymentPostprocessing = 0; }};")
add("/* End PBXSourcesBuildPhase section */"); add("")

def cfg(cid, name_, settings):
    add(f"\t\t{cid} /* {name_} */ = {{isa = XCBuildConfiguration; buildSettings = {{")
    for s in settings: add(f"\t\t\t\t{s}")
    add("\t\t\t};"); add(f"\t\t\tname = {name_}; }};")

add("/* Begin XCBuildConfiguration section */")
proj = ["ALWAYS_SEARCH_USER_PATHS = NO;","CLANG_ANALYZER_NONNULL = YES;","CLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";","CLANG_ENABLE_MODULES = YES;","CLANG_ENABLE_OBJC_ARC = YES;","IPHONEOS_DEPLOYMENT_TARGET = 16.0;","SDKROOT = iphoneos;","SWIFT_VERSION = 5.0;"]
cfg(fid(11000001), "Debug", proj + ["DEBUG_INFORMATION_FORMAT = dwarf;","GCC_OPTIMIZATION_LEVEL = 0;","ONLY_ACTIVE_ARCH = YES;","SWIFT_OPTIMIZATION_LEVEL = \"-Onone\";"])
cfg(fid(11000002), "Release", proj + ["DEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";","GCC_OPTIMIZATION_LEVEL = s;","SWIFT_OPTIMIZATION_LEVEL = \"-O\";"])
tgt = ["CODE_SIGN_STYLE = Automatic;","CURRENT_PROJECT_VERSION = 1;","INFOPLIST_FILE = Info.plist;","MARKETING_VERSION = 1.0;","PRODUCT_BUNDLE_IDENTIFIER = com.clothingar.app;","PRODUCT_NAME = \"$(TARGET_NAME)\";","SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\";","SWIFT_VERSION = 5.0;","TARGETED_DEVICE_FAMILY = 1;","LD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\",\"@executable_path/Frameworks\");","INFOPLIST_KEY_NSCameraUsageDescription = \"ClothingAR 需要使用相机\";","INFOPLIST_KEY_NSMicrophoneUsageDescription = \"ClothingAR 需要使用麦克风\";","INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription = \"ClothingAR 需要保存视频\";","INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;","INFOPLIST_KEY_UILaunchScreen_Generation = YES;","INFOPLIST_KEY_UIStatusBarHidden = YES;","INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;"]
cfg(fid(11000003), "Debug", tgt)
cfg(fid(11000004), "Release", tgt)
add("/* End XCBuildConfiguration section */"); add("")

add("/* Begin XCConfigurationList section */")
add(f"\t\t{fid(8000002)} /* BCL target */ = {{isa = XCConfigurationList; buildConfigurations = ({fid(11000003)} /* Debug */,{fid(11000004)} /* Release */,); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};")
add(f"\t\t{fid(8000001)} /* BCL project */ = {{isa = XCConfigurationList; buildConfigurations = ({fid(11000001)} /* Debug */,{fid(11000002)} /* Release */,); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};")
add("/* End XCConfigurationList section */"); add("")

add("\t};"); add(f"\trootObject = {PRJ} /* Project object */;"); add("}")

os.makedirs("ClothingAR.xcodeproj", exist_ok=True)
with open("ClothingAR.xcodeproj/project.pbxproj", "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(L) + "\n")
print("pbxproj generated successfully")
