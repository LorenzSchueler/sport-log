import 'package:flutter/material.dart';
import 'package:sport_log/widgets/custom_icons.dart';

abstract final class AppIcons {
  // This Class has 3 purposes:
  // - combine Icons and CustomIcons in one class
  // - give Icons more intuitive names
  // - make sure that always the same kind of icon (outlined, rounded, ...) is used

  // custom icons
  static const IconData dumbbell = CustomIcons.dumbbell;
  static const IconData plan = CustomIcons.plan;
  static const IconData repeat = CustomIcons.cw;
  static const IconData timeInterval = CustomIcons.time_interval;
  static const IconData github = CustomIcons.github;
  static const IconData gauge = CustomIcons.gauge;
  static const IconData food = CustomIcons.food;
  static const IconData heartbeat = CustomIcons.heartbeat;
  static const IconData weight = CustomIcons.weight;
  static const IconData route = CustomIcons.route;
  static const IconData ruler = CustomIcons.ruler_horizontal;
  static const IconData medal = CustomIcons.medal;
  static const IconData compass = CustomIcons.compass;

  // actions
  static const IconData add = Icons.add_rounded;
  static const IconData remove = Icons.remove_rounded;
  static const IconData addBox = Icons.add_box_rounded;
  static const IconData subtractBox = Icons.indeterminate_check_box_rounded;
  static const IconData delete = Icons.delete_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData save = Icons.save_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData checkBox = Icons.check_box_outlined;
  static const IconData checkCircle = Icons.check_circle_outline_rounded;
  static const IconData undo = Icons.undo_rounded;
  static const IconData restore = Icons.settings_backup_restore_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData logout = Icons.logout_rounded;
  static const IconData download = Icons.download_rounded;
  static const IconData sync = Icons.sync_rounded;
  static const IconData openInBrowser = Icons.open_in_browser_outlined;
  static const IconData fileDownload = Icons.file_download_rounded;
  static const IconData dragHandle = Icons.drag_handle_rounded;
  static const IconData upload = Icons.upload_rounded;
  static const IconData cut = Icons.cut_rounded;
  static const IconData fullScreen = Icons.fullscreen_rounded;
  static const IconData closeFullScreen = Icons.close_fullscreen_rounded;
  static const IconData visibility = Icons.visibility_outlined;
  static const IconData visibilityOff = Icons.visibility_off_outlined;
  static const IconData centerFocus = Icons.center_focus_strong_rounded;
  static const IconData centerFocusOff = Icons.center_focus_weak_rounded;
  static const IconData threeD = Icons.threed_rotation_rounded;
  static const IconData invertColors = Icons.invert_colors_rounded;
  static const IconData info = Icons.info_outline_rounded;
  static const IconData combine = Icons.merge;
  static const IconData colorLens = Icons.color_lens_outlined;
  static const IconData hammer = Icons.handyman_rounded;

  // arrows
  static const IconData arrowLeft = Icons.arrow_back_ios_rounded;
  static const IconData arrowRight = Icons.arrow_forward_ios_rounded;
  static const IconData arrowDropDown = Icons.arrow_drop_down_rounded;
  static const IconData arrowUp = Icons.keyboard_arrow_up_rounded;
  static const IconData arrowDown = Icons.keyboard_arrow_down_rounded;
  static const IconData trendingUp = Icons.trending_up_rounded;
  static const IconData trendingDown = Icons.trending_down_rounded;

  static const IconData filterFilled = Icons.filter_alt_rounded;
  static const IconData filter = Icons.filter_alt_outlined;

  // fields
  static const IconData settings = Icons.settings_rounded;
  static const IconData questionMark = Icons.question_mark_rounded;
  static const IconData email = Icons.email_outlined;
  static const IconData key = Icons.key_outlined;
  static const IconData map = Icons.map_rounded;
  static const IconData stopwatch = Icons.timer_outlined;
  static const IconData sports = Icons.sports_rounded;
  static const IconData comment = Icons.comment_outlined;
  static const IconData movement = Icons.directions_run_rounded;
  static const IconData calendar = Icons.calendar_today_rounded;
  static const IconData notes = Icons.notes_rounded;
  static const IconData cloudUpload = Icons.cloud_upload_outlined;
  static const IconData account = Icons.account_circle_outlined;
  static const IconData contributors = Icons.supervised_user_circle_outlined;
  static const IconData copyright = Icons.copyright_outlined;
  static const IconData playCircle = Icons.play_circle_outline;
  static const IconData timeline = Icons.timeline_rounded;
  static const IconData car = Icons.directions_car_rounded;
  static const IconData satellite = Icons.satellite_rounded;
  static const IconData location = Icons.location_on;
  static const IconData addLocation = Icons.add_location_alt_outlined;
  static const IconData myLocationBackground = Icons.my_location_rounded;
  static const IconData myLocationForeground = Icons.location_searching_rounded;
  static const IconData myLocationOff = Icons.location_disabled_rounded;
  static const IconData battery = Icons.battery_std_rounded;
  static const IconData radio = Icons.radio_button_checked_rounded;
  static const IconData clock = Icons.access_time_rounded;
  static const IconData drawer = Icons.dehaze_rounded;
  static const IconData mountains = Icons.filter_hdr_rounded;
  static const IconData layers = Icons.layers_rounded;
  static const IconData developerMode = Icons.developer_mode;
  static const IconData numberedList = Icons.format_list_numbered_rounded;
  static const IconData bulletedList = Icons.format_list_bulleted_rounded;
  static const IconData chart = Icons.timeline_rounded;
  static const IconData compare = Icons.compare_rounded;
  static const IconData notification = Icons.notifications_active_rounded;
  static const IconData systemUpdate = Icons.system_update_rounded;
  static const IconData star = Icons.star_rounded;
}
