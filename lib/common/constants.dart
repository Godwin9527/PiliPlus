abstract final class Constants {
  static const appName = 'PiliPlus';

  /// 本 App 的源代码仓库地址。
  ///
  /// 通过构建参数 `pili.repo` 注入（见 `lib/scripts/build.ps1` 与
  /// `.github/workflows/build.yml`）。未注入时回退为上游原仓库，
  /// 因此本文件无需为 fork 做任何硬编码修改。
  static const String _repo = String.fromEnvironment(
    'pili.repo',
    defaultValue: 'bggRGjQaUbCoE/PiliPlus',
  );
  static const sourceCodeUrl = 'https://github.com/$_repo';

  // 27eb53fc9058f8c3  移动端 Android
  // 4409e2ce8ffd12b8  HD版
  static const String appKey = 'dfca71928277209b';
  // 59b43e04ad6965f34319062b478f83dd TV端
  static const String appSec = 'b5475a8825547a4fc26c7d518eaaa02e';
  // static const String thirdSign = '04224646d1fea004e79606d3b038c84a';
  // static const String thirdApi =
  //     'https://www.mcbbs.net/template/mcbbs/image/special_photo_bg.png';

  static const String traceId =
      '11111111111111111111111111111111:1111111111111111:0:0';
  static const String userAgent =
      'Mozilla/5.0 BiliDroid/2.0.1 (bbcallen@gmail.com) os/android model/android_hd mobi_app/android_hd build/2001100 channel/master innerVer/2001100 osVer/15 network/2';
  static const String statistics =
      '{"appId":5,"platform":3,"version":"2.0.1","abtest":""}';
  // 请求时会自动encodeComponent

  // app
  static const String userAgentApp =
      'Mozilla/5.0 BiliDroid/8.43.0 (bbcallen@gmail.com) os/android model/android mobi_app/android build/8430300 channel/master innerVer/8430300 osVer/15 network/2';

  static const String statisticsApp =
      '{"appId":1,"platform":3,"version":"8.43.0","abtest":""}';

  static const baseHeaders = {
    // 'referer': HttpString.baseUrl,
    'env': 'prod',
    'app-key': 'android64',
    'x-bili-aurora-zone': 'sh001',
  };

  static final urlRegex = RegExp(
    r'https?://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]',
  );

  static const goodsUrlPrefix = "https://gaoneng.bilibili.com/tetris";

  // static const dynFeatures = 'itemOpusStyle,listOnlyfans,onlyfansQaCard';
  static const dynFeatures =
      'itemOpusStyle,listOnlyfans,opusBigCover,onlyfansVote,decorationCard,onlyfansAssetsV2,forwardListHidden,ugcDelete,onlyfansQaCard,commentsNewVersion,avatarAutoTheme,sunflowerStyle,cardsEnhance,eva3CardOpus,eva3CardVideo,eva3CardComment,eva3CardVote,eva3CardUser';

  static const dynDetailFeatures =
      'itemOpusStyle,opusBigCover,onlyfansVote,endFooterHidden,decorationCard,onlyfansAssetsV2,ugcDelete,onlyfansQaCard,editable,opusPrivateVisible,avatarAutoTheme,sunflowerStyle,cardsEnhance,eva3CardOpus,eva3CardVideo,eva3CardComment,eva3CardVote,eva3CardUser';

  static const opusDetailFeatures =
      'onlyfansVote,onlyfansAssetsV2,onlyfansOpusCard,decorationCard,htmlNewStyle,ugcDelete,editable,opusPrivateVisible,opusTribeeApprovedThread,opusTribeeRejectThread,opusTribeeFeatured,opusTribeeModifyCategory,opusTribeeRemoveThread,opusTribeeCoin,tribeeEdit,avatarAutoTheme,avatarTypeOpus,sunflowerStyle,articleEnhance,cardsEnhance,eva3CardOpus,eva3CardVideo,eva3CardComment,eva3CardVote,eva3CardUser';
}
