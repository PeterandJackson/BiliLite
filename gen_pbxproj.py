#!/usr/bin/env python3
"""Generate valid BiliLite.xcodeproj/project.pbxproj — strict OpenStep plist format."""
import os, sys

FILES = [
    ("BiliLiteApp.swift",           "App"),
    ("APIResponse.swift",           "Models"),
    ("Video.swift",                 "Models"),
    ("VideoDetail.swift",           "Models"),
    ("VideoStream.swift",           "Models"),
    ("Comment.swift",               "Models"),
    ("SearchResult.swift",          "Models"),
    ("UserProfile.swift",           "Models"),
    ("BiliAPIClient.swift",         "Services"),
    ("WBISigner.swift",             "Services"),
    ("DeviceIdentity.swift",        "Services"),
    ("ImageCache.swift",            "Services"),
    ("DanmakuParser.swift",         "Services"),
    ("HomeViewModel.swift",         "ViewModels"),
    ("VideoDetailViewModel.swift",  "ViewModels"),
    ("PlayerViewModel.swift",       "ViewModels"),
    ("SearchViewModel.swift",       "ViewModels"),
    ("CommentViewModel.swift",      "ViewModels"),
    ("LoginViewModel.swift",        "ViewModels"),
    ("FavoritesViewModel.swift",    "ViewModels"),
    ("LiveViewModel.swift",         "ViewModels"),
    ("MainTabView.swift",           "Views"),
    ("HomeView.swift",              "Views/Home"),
    ("VideoCard.swift",             "Views/Home"),
    ("VideoDetailView.swift",       "Views/Detail"),
    ("CommentListView.swift",       "Views/Detail"),
    ("VideoPlayerView.swift",       "Views/Player"),
    ("PlayerOverlay.swift",         "Views/Player"),
    ("DanmakuView.swift",           "Views/Player"),
    ("SearchView.swift",            "Views/Search"),
    ("LoginView.swift",             "Views"),
    ("LiveView.swift",              "Views"),
    ("CachedAsyncImage.swift",      "Views/Common"),
    ("LoadingView.swift",           "Views/Common"),
    ("ErrorBanner.swift",           "Views/Common"),
    ("Constants.swift",             "Utils"),
    ("ViewExtensions.swift",        "Utils"),
    ("Info.plist",                  "Resources"),
    ("Assets.xcassets",             "Resources"),
]

# ---- IDs ----
def fid(n): return f"{n:024X}"
IDX = {}; BID = {}; FREF = {}
for i, (name, _) in enumerate(FILES):
    IDX[name] = i
    BID[name] = fid(1000001 + i)
    FREF[name] = fid(2000001 + i)
PROD = fid(2999999)
FWB  = fid(3000001)
SRC  = fid(6000001)
RES  = fid(7000001)
TGT  = fid(5000001)
PRJ  = fid(9000001)

out = []

def L(s=""): out.append(s)

# ---- HEADER (RFC: // !$*UTF8*$! then root dict) ----
L("// !$*UTF8*$!")
L("{")
L("\tarchiveVersion = 1;")
L("\tclasses = {")
L("\t};")
L("\tobjectVersion = 56;")
L("\tobjects = {")
L("")

# ===== PBXBuildFile =====
L("/* Begin PBXBuildFile section */")
for name, group in FILES:
    r = FREF[name]
    if name == "Assets.xcassets":
        L(f"\t\t{BID[name]} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {r} /* {name} */; }};")
    elif name == "Info.plist":
        pass  # not built
    else:
        L(f"\t\t{BID[name]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {r} /* {name} */; }};")
L("/* End PBXBuildFile section */")
L("")

# ===== PBXFileReference =====
L("/* Begin PBXFileReference section */")
for name, group in FILES:
    r = FREF[name]
    if name == "Assets.xcassets":
        L(f"\t\t{r} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = {name}; sourceTree = \"<group>\"; }};")
    elif name == "Info.plist":
        L(f"\t\t{r} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = {name}; sourceTree = \"<group>\"; }};")
    else:
        L(f"\t\t{r} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};")
L(f"\t\t{PROD} /* BiliLite.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = BiliLite.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
L("/* End PBXFileReference section */")
L("")

# ===== PBXFrameworksBuildPhase =====
L("/* Begin PBXFrameworksBuildPhase section */")
L(f"\t\t{FWB} /* Frameworks */ = {{")
L("\t\t\tisa = PBXFrameworksBuildPhase;")
L("\t\t\tbuildActionMask = 2147483647;")
L("\t\t\tfiles = (")
L("\t\t\t);")
L("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
L("\t\t};")
L("/* End PBXFrameworksBuildPhase section */")
L("")

# ===== PBXGroup =====
G = {}
for k in ["ROOT","App","Models","Services","ViewModels","Views","Views/Home",
           "Views/Detail","Views/Player","Views/Search","Views/Common","Utils","Resources","Products"]:
    G[k] = fid(4000000 + len(G))

def group(gid, refs, name="", path=""):
    label = name or path or ""
    L(f"\t\t{gid} /* {label} */ = {{")
    L("\t\t\tisa = PBXGroup;")
    L("\t\t\tchildren = (")
    for c in refs:
        L(f"\t\t\t\t{c},")
    L("\t\t\t);")
    if name:
        L(f"\t\t\tname = {name};")
    if path:
        L(f"\t\t\tpath = {path};")
    L("\t\t\tsourceTree = \"<group>\";")
    L("\t\t};")

L("/* Begin PBXGroup section */")

def refs_for(gname):
    return [FREF[n] for n, g in FILES if g == gname]

group(G["App"],       refs_for("App"),       path="App")
group(G["Models"],    refs_for("Models"),    path="Models")
group(G["Services"],  refs_for("Services"),  path="Services")
group(G["ViewModels"],refs_for("ViewModels"),path="ViewModels")
group(G["Views/Home"],  refs_for("Views/Home"),  path="Home")
group(G["Views/Detail"],refs_for("Views/Detail"),path="Detail")
group(G["Views/Player"],refs_for("Views/Player"),path="Player")
group(G["Views/Search"],refs_for("Views/Search"),path="Search")
group(G["Views/Common"],refs_for("Views/Common"),path="Common")

# Views parent
views_direct = refs_for("Views")
views_subs = [G["Views/Home"], G["Views/Detail"], G["Views/Player"], G["Views/Search"], G["Views/Common"]]
group(G["Views"], views_direct + views_subs, name="Views", path="Views")

group(G["Utils"],     refs_for("Utils"),     path="Utils")
group(G["Resources"], [FREF["Info.plist"], FREF["Assets.xcassets"]], path="Resources")
group(G["Products"],  [PROD],                name="Products")

root_children = [G["App"], G["Models"], G["Services"], G["ViewModels"],
                 G["Views"], G["Utils"], G["Resources"], G["Products"]]
group(G["ROOT"], root_children)

L("/* End PBXGroup section */")
L("")

# ===== PBXNativeTarget =====
L("/* Begin PBXNativeTarget section */")
L(f"\t\t{TGT} /* BiliLite */ = {{")
L("\t\t\tisa = PBXNativeTarget;")
L(f"\t\t\tbuildConfigurationList = {fid(8000002)} /* Build configuration list for PBXNativeTarget \"BiliLite\" */;")
L("\t\t\tbuildPhases = (")
L(f"\t\t\t\t{SRC} /* Sources */,")
L(f"\t\t\t\t{FWB} /* Frameworks */,")
L(f"\t\t\t\t{RES} /* Resources */,")
L("\t\t\t);")
L("\t\t\tbuildRules = (")
L("\t\t\t);")
L("\t\t\tdependencies = (")
L("\t\t\t);")
L("\t\t\tname = BiliLite;")
L("\t\t\tproductName = BiliLite;")
L(f"\t\t\tproductReference = {PROD} /* BiliLite.app */;")
L("\t\t\tproductType = \"com.apple.product-type.application\";")
L("\t\t};")
L("/* End PBXNativeTarget section */")
L("")

# ===== PBXProject =====
L("/* Begin PBXProject section */")
L(f"\t\t{PRJ} /* Project object */ = {{")
L("\t\t\tisa = PBXProject;")
L("\t\t\tattributes = {")
L("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
L("\t\t\t\tLastSwiftUpdateCheck = 1520;")
L("\t\t\t\tLastUpgradeCheck = 1520;")
L("\t\t\t\tTargetAttributes = {")
L(f"\t\t\t\t\t{TGT} = {{")
L("\t\t\t\t\t\tCreatedOnToolsVersion = 15.2;")
L("\t\t\t\t\t};")
L("\t\t\t\t};")
L("\t\t\t};")
L(f"\t\t\tbuildConfigurationList = {fid(8000001)} /* Build configuration list for PBXProject \"BiliLite\" */;")
L("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
L("\t\t\tdevelopmentRegion = \"zh-Hans\";")
L("\t\t\thasScannedForEncodings = 0;")
L("\t\t\tknownRegions = (")
L("\t\t\t\ten,")
L("\t\t\t\t\"zh-Hans\",")
L("\t\t\t\tBase,")
L("\t\t\t);")
L(f"\t\t\tmainGroup = {G['ROOT']};")
L(f"\t\t\tproductRefGroup = {G['Products']} /* Products */;")
L("\t\t\tprojectDirPath = \"\";")
L("\t\t\tprojectRoot = \"\";")
L("\t\t\ttargets = (")
L(f"\t\t\t\t{TGT} /* BiliLite */,")
L("\t\t\t);")
L("\t\t};")
L("/* End PBXProject section */")
L("")

# ===== PBXResourcesBuildPhase =====
L("/* Begin PBXResourcesBuildPhase section */")
L(f"\t\t{RES} /* Resources */ = {{")
L("\t\t\tisa = PBXResourcesBuildPhase;")
L("\t\t\tbuildActionMask = 2147483647;")
L("\t\t\tfiles = (")
L(f"\t\t\t\t{BID['Assets.xcassets']} /* Assets.xcassets in Resources */,")
L("\t\t\t);")
L("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
L("\t\t};")
L("/* End PBXResourcesBuildPhase section */")
L("")

# ===== PBXSourcesBuildPhase =====
L("/* Begin PBXSourcesBuildPhase section */")
L(f"\t\t{SRC} /* Sources */ = {{")
L("\t\t\tisa = PBXSourcesBuildPhase;")
L("\t\t\tbuildActionMask = 2147483647;")
L("\t\t\tfiles = (")
for name, group in FILES:
    if name not in ("Assets.xcassets", "Info.plist"):
        L(f"\t\t\t\t{BID[name]} /* {name} in Sources */,")
L("\t\t\t);")
L("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
L("\t\t};")
L("/* End PBXSourcesBuildPhase section */")
L("")

# ===== XCBuildConfiguration =====
def cfg(cid, name, settings):
    L(f"\t\t{cid} /* {name} */ = {{")
    L("\t\t\tisa = XCBuildConfiguration;")
    L("\t\t\tbuildSettings = {")
    for s in settings:
        L(f"\t\t\t\t{s}")
    L("\t\t\t};")
    L(f"\t\t\tname = {name};")
    L("\t\t};")

L("/* Begin XCBuildConfiguration section */")

PROJ_COMMON = [
    'ALWAYS_SEARCH_USER_PATHS = NO;',
    'CLANG_ANALYZER_NONNULL = YES;',
    'CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";',
    'CLANG_ENABLE_MODULES = YES;',
    'CLANG_ENABLE_OBJC_ARC = YES;',
    'IPHONEOS_DEPLOYMENT_TARGET = 16.0;',
    'SDKROOT = iphoneos;',
    'SWIFT_VERSION = 5.0;',
]
cfg(fid(11000001), "Debug", PROJ_COMMON + [
    'DEBUG_INFORMATION_FORMAT = dwarf;',
    'GCC_OPTIMIZATION_LEVEL = 0;',
    'ONLY_ACTIVE_ARCH = YES;',
    'SWIFT_OPTIMIZATION_LEVEL = "-Onone";',
])
cfg(fid(11000002), "Release", PROJ_COMMON + [
    'DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";',
    'GCC_OPTIMIZATION_LEVEL = s;',
    'SWIFT_OPTIMIZATION_LEVEL = "-O";',
    'VALIDATE_PRODUCT = YES;',
])

TGT_COMMON = [
    'CODE_SIGN_STYLE = Automatic;',
    'CURRENT_PROJECT_VERSION = 1;',
    'INFOPLIST_FILE = Info.plist;',
    'MARKETING_VERSION = 1.0;',
    'PRODUCT_BUNDLE_IDENTIFIER = com.bililite.app;',
    'PRODUCT_NAME = "$(TARGET_NAME)";',
    'SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";',
    'SWIFT_VERSION = 5.0;',
    'TARGETED_DEVICE_FAMILY = 1;',
    'LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");',
]
cfg(fid(11000003), "Debug", TGT_COMMON)
cfg(fid(11000004), "Release", TGT_COMMON)

L("/* End XCBuildConfiguration section */")
L("")

# ===== XCConfigurationList =====
L("/* Begin XCConfigurationList section */")
for clid, label, d, r in [
    (fid(8000001), 'Build configuration list for PBXProject "BiliLite"', fid(11000001), fid(11000002)),
    (fid(8000002), 'Build configuration list for PBXNativeTarget "BiliLite"', fid(11000003), fid(11000004)),
]:
    L(f"\t\t{clid} /* {label} */ = {{")
    L("\t\t\tisa = XCConfigurationList;")
    L("\t\t\tbuildConfigurations = (")
    L(f"\t\t\t\t{d} /* Debug */,")
    L(f"\t\t\t\t{r} /* Release */,")
    L("\t\t\t);")
    L("\t\t\tdefaultConfigurationIsVisible = 0;")
    L("\t\t\tdefaultConfigurationName = Release;")
    L("\t\t};")
L("/* End XCConfigurationList section */")
L("")

# ===== FOOTER =====
L("\t};")
L(f"\trootObject = {PRJ} /* Project object */;")
L("}")

with open("BiliLite.xcodeproj/project.pbxproj", "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(out) + "\n")
print(f"pbxproj written — {len(out)} lines, {len(FILES)} files")
