import '../models/video_item.dart';

/// 本地模拟视频数据
/// 实际使用时，将真实视频放入 assets/videos/ 目录，
/// 并将对应路径替换为实际文件名（如 'assets/videos/demo1.mp4'）
class MockVideoData {
  static const List<VideoItem> items = [
    // ────────────────────────────────────────
    // 产品：智能摄像头
    // ────────────────────────────────────────
    VideoItem(
      id: '001',
      title: '智能摄像头 - 家庭安防布防演示',
      description: '展示如何通过 App 快速完成家庭摄像头布防设置，包括运动检测区域划定、告警推送配置等完整流程。',
      videoPath: 'assets/videos/camera_home_security.mp4',
      thumbnailPath: 'assets/thumbnails/thumb_001.jpg',
      product: '智能摄像头',
      scene: '家庭安防',
      caseTag: '快速布防',
    ),
    VideoItem(
      id: '002',
      title: '智能摄像头 - 人脸识别门禁联动',
      description: '演示摄像头人脸识别与门禁系统的联动方案，实现刷脸开门及陌生人告警。',
      videoPath: 'assets/videos/camera_face_door.mp4',
      thumbnailPath: 'assets/thumbnails/thumb_002.jpg',
      product: '智能摄像头',
      scene: '门禁管理',
      caseTag: '人脸识别',
    ),
    VideoItem(
      id: '003',
      title: '智能摄像头 - 商超收银区监控方案',
      description: '针对商超收银区的摄像头部署方案，支持多角度覆盖和异常行为检测。',
      videoPath: 'assets/videos/camera_retail_checkout.mp4',
      thumbnailPath: 'assets/thumbnails/thumb_003.jpg',
      product: '智能摄像头',
      scene: '商业零售',
      caseTag: '收银监控',
    ),
    VideoItem(
      id: '004',
      title: '智能摄像头 - 工厂产线巡检',
      description: '展示摄像头在工厂产线上的 AI 质检应用，自动识别缺陷产品并记录。',
      videoPath: 'assets/videos/camera_factory_inspection.mp4',
      thumbnailPath: 'assets/thumbnails/thumb_004.jpg',
      product: '智能摄像头',
      scene: '工业制造',
      caseTag: 'AI质检',
    ),

    // ────────────────────────────────────────
    // 产品：智能门锁
    // ────────────────────────────────────────
    VideoItem(
      id: '005',
      title: '智能门锁 - 远程开锁操作演示',
      description: '通过手机 App 实现远程开锁，支持临时密码生成和开锁记录查看。',
      videoPath: 'assets/videos/lock_remote_open.mp4',
      thumbnailPath: 'assets/thumbnails/thumb_005.jpg',
      product: '智能门锁',
      scene: '远程管理',
      caseTag: '远程开锁',
    ),
    VideoItem(
      id: '006',
      title: '智能门锁 - 酒店客房自助入住',
      description: '展示酒店场景下客人通过手机扫码自助获取门锁权限，免前台排队。',
      videoPath: 'assets/videos/lock_hotel_checkin.mp4',
      thumbnailPath: 'assets/thumbnails/thumb_006.jpg',
      product: '智能门锁',
      scene: '酒店管理',
      caseTag: '自助入住',
    ),
    VideoItem(
      id: '007',
      title: '智能门锁 - 租房临时授权方案',
      description: '演示房东如何为租客设置有时效的门锁权限，到期自动失效。',
      videoPath: 'assets/videos/lock_rental_auth.mp4',
      thumbnailPath: 'assets/thumbnails/thumb_007.jpg',
      product: '智能门锁',
      scene: '租房管理',
      caseTag: '临时授权',
    ),

    // ────────────────────────────────────────
    // 产品：智能网关
    // ────────────────────────────────────────
    VideoItem(
      id: '008',
      title: '智能网关 - 家居全屋联动场景',
      description: '演示网关作为家居中枢，联动灯光、空调、窗帘的一键场景控制。',
      videoPath: 'assets/videos/gateway_home_scene.mp4',
      thumbnailPath: 'assets/thumbnails/thumb_008.jpg',
      product: '智能网关',
      scene: '全屋智能',
      caseTag: '场景联动',
    ),
    VideoItem(
      id: '009',
      title: '智能网关 - 工业设备数据采集',
      description: '展示网关在工业场景下聚合多协议设备数据，并上传至云端平台的完整流程。',
      videoPath: 'assets/videos/gateway_industry_data.mp4',
      thumbnailPath: 'assets/thumbnails/thumb_009.jpg',
      product: '智能网关',
      scene: '工业制造',
      caseTag: '数据采集',
    ),
    VideoItem(
      id: '010',
      title: '智能网关 - 智慧楼宇能耗管理',
      description: '演示网关接入楼宇各子系统，实现能耗数据的统一监测和分析报表生成。',
      videoPath: 'assets/videos/gateway_building_energy.mp4',
      thumbnailPath: 'assets/thumbnails/thumb_010.jpg',
      product: '智能网关',
      scene: '楼宇管理',
      caseTag: '能耗管理',
    ),

    // ────────────────────────────────────────
    // 产品：云平台
    // ────────────────────────────────────────
    VideoItem(
      id: '011',
      title: '云平台 - 设备批量配网操作',
      description: '展示如何在云平台上对大量 IoT 设备进行批量配网、固件升级操作。',
      videoPath: 'assets/videos/cloud_batch_provision.mp4',
      thumbnailPath: 'assets/thumbnails/thumb_011.jpg',
      product: '云平台',
      scene: '设备管理',
      caseTag: '批量配网',
    ),
    VideoItem(
      id: '012',
      title: '云平台 - 数据大屏可视化展示',
      description: '演示基于云平台数据的大屏可视化方案，实时展示设备状态、告警统计等核心指标。',
      videoPath: 'assets/videos/cloud_dashboard.mp4',
      thumbnailPath: 'assets/thumbnails/thumb_012.jpg',
      product: '云平台',
      scene: '数据可视化',
      caseTag: '大屏展示',
    ),
  ];

  /// 获取所有产品列表（去重）
  static List<String> get allProducts =>
      items.map((e) => e.product).toSet().toList()..sort();

  /// 获取所有场景列表（去重）
  static List<String> get allScenes =>
      items.map((e) => e.scene).toSet().toList()..sort();

  /// 获取所有案例标签列表（去重）
  static List<String> get allCaseTags =>
      items.map((e) => e.caseTag).toSet().toList()..sort();
}
