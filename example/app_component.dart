// Copyright (c) 2017, Adam Lofts. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:angular2/angular2.dart';
import 'package:angular_quill/angular_quill.dart';

@Component(
  selector: 'my-app',
  styleUrls: const ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: const [COMMON_DIRECTIVES, quillDirectives],
)
class AppComponent {
  List<String> events = [];
  String html = "";

  void blur() {
    events.insert(0, "${new DateTime.now()} blur");
  }

  void input() {
    events.insert(0, "${new DateTime.now()} input");
  }
}
