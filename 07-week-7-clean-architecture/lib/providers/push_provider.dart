import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../messaging/push_services.dart';

final pushServiceProvider = Provider<PushService>((ref) => PushService());
