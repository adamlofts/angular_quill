import 'dart:async';
import 'dart:html' show Element;
import 'dart:js_util' show jsify;

import 'package:ngdart/angular.dart';
import 'package:ngforms/ngforms.dart';
import "package:js/js.dart" show allowInterop;

import 'quill.dart' as quill;

@Directive(selector: 'quill[ngModel]', providers: const [
  const Provider(ngValueAccessor, useExisting: QuillValueAccessor)
])
class QuillValueAccessor implements ControlValueAccessor<String>, OnDestroy {
  final QuillComponent _quill;
  late StreamSubscription _blurSub;
  late StreamSubscription _inputSub;

  TouchFunction onTouched = () {};
  ChangeFunction<String> onChange = (String _, {String rawValue=''}) {};

  QuillValueAccessor(this._quill) {
    _inputSub = _quill.input.listen(_onInput);
    _blurSub = _quill.blur.listen(_onBlur);
  }

  @override
  ngOnDestroy() {
    _blurSub.cancel();
    _inputSub.cancel();
  }

  /// Write a new value to the element.
  @override
  void writeValue(String obj) {
    _quill.value = obj;
  }

  void _onBlur(_) {
    onTouched();
  }

  void _onInput(_) {
    onChange(_quill.value);
  }

  /// Set the function to be called when the control receives a change event.
  @override
  void registerOnChange(ChangeFunction<String> fn) {
    this.onChange = fn;
  }

  /// Set the function to be called when the control receives a touch event.
  @override
  void registerOnTouched(TouchFunction fn) {
    onTouched = fn;
  }

  @override
  void onDisabledChanged(bool isDisabled) {
    _quill.disabled = isDisabled;
  }
}

@Component(
  selector: 'quill',
  templateUrl: 'quill_component.html',
)
class QuillComponent implements AfterContentInit, OnDestroy {
  quill.QuillStatic? quillEditor;

  @ViewChild('editor')
  Element? editor;

  String _initialValue = '';
  String get value {
    final ed = editor!;
    if (ed.children.isEmpty != false) {
      return '';
    }
    return ed.children.first.innerHtml ?? '';
  }

  @Input()
  set value(String v) {
    if (quillEditor == null) {
      _initialValue = v;
      return;
    }
    quillEditor!.pasteHTML(v);
  }

  @Input()
  String placeholder = '';

  @Input()
  dynamic modules = {};

  bool _disabled = false;
  bool get disabled => _disabled;
  @Input()
  set disabled(bool v) {
    _disabled = v;
    // The editor may not have been created yet
    if (quillEditor != null) {
      quillEditor!.enable(!v);
    }
  }

  final StreamController _blur = new StreamController.broadcast();
  @Output()
  Stream get blur => _blur.stream;

  final StreamController _focus = new StreamController();
  @Output()
  Stream get focus => _focus.stream;

  final StreamController _input = new StreamController.broadcast();
  @Output()
  Stream get input => _input.stream;

  var _selectionChangeSub;
  var _textChangeSub;

  @override
  ngAfterContentInit() {
    final newEditor = new quill.QuillStatic(editor,
      new quill.QuillOptionsStatic(
        theme: 'snow',
        placeholder: placeholder,
        modules: jsify(modules)
      )
    );

    _textChangeSub = allowInterop(_onTextChange);
    _selectionChangeSub = allowInterop(_onSelectionChange);
    newEditor.on('text-change', _textChangeSub);
    newEditor.on('selection-change', _selectionChangeSub);

    newEditor.enable(!_disabled);
    newEditor.pasteHTML(_initialValue);

    quillEditor = newEditor;
  }

  @override
  ngOnDestroy() {
    quillEditor!.off('text-change', _textChangeSub);
    quillEditor!.off('selection-change', _selectionChangeSub);

    // quill docs say no explicit destroy call is required.
  }

  /// Emitted when a user or API causes the selection to change, with a range representing the selection boundaries.
  ///
  /// When range changes from null value to non-null value, it indicates focus lost so we emit [blur] event.
  /// When range changes from non-null value to null value, it indicates gain of focus so we emit [focus] event.
  void _onSelectionChange(range, oldRange, String source) {
    if (oldRange != null && range == null) {
      // null range indicates blur event
      _blur.add(null);
    } else if (oldRange == null && range != null) {
      // change from null to non-null range indicates focus event
      _focus.add(null);
    }
  }

  /// Emitted when the contents of Quill have changed. Details of the change, representation of the editor contents
  /// before the change, along with the source of the change are provided. The source will be "user" if it originates from the users
  void _onTextChange(delta, oldDelta, source) {
    _input.add(value);
  }
}
