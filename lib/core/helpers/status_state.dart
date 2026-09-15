import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';

abstract class StatusState {
  GeneralStatus get generalStatus;
  DialogMessage get dialogMessage;
}
