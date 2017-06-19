
import 'dart:async';
import 'dart:html' show Element;

import 'package:angular2/angular2.dart';
import 'package:func/func.dart' show VoidFunc0, VoidFunc1;
import "package:js/js.dart" show allowInterop;

import 'quill.dart' as quill;

@Directive(
    selector: 'quill[ngModel]',
    providers: const [
      const Provider(NG_VALUE_ACCESSOR, useExisting: QuillValueAccessor, multi: true)
    ]
)
class QuillValueAccessor implements ControlValueAccessor<String>, OnDestroy {
  final QuillComponent _quill;
  StreamSubscription _blurSub;
  StreamSubscription _inputSub;

  VoidFunc0 onTouched = () {};
  VoidFunc1 onChange = (dynamic _) {};

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
  void registerOnChange(void fn(dynamic _, {String rawValue})) {
    this.onChange = (value) {
      fn(value, rawValue: value);
    };
  }
  /// Set the function to be called when the control receives a touch event.
  @override
  void registerOnTouched(void fn()) {
    onTouched = fn;
  }
}

@Component(
  selector: 'quill',
  templateUrl: 'quill_component.html',
)
class QuillComponent implements AfterContentInit, OnDestroy {
  quill.QuillStatic quillEditor;

  @ViewChild('editor')
  ElementRef editor;

  String _initialValue = '';
  String get value {
    Element elmt = editor.nativeElement;
    if (elmt.children.isEmpty) {
      return '';
    }
    return elmt.children.first.innerHtml;
  }
  @Input()
  set value (String val) {
    String v = val ?? '';
    if (quillEditor == null) {
      _initialValue = val;
      return;
    }
    quillEditor.pasteHTML(v);
  }

  @Input()
  String placeholder = '';

  bool _disabled = false;
  bool get disabled => _disabled;
  @Input()
  set disabled(bool v) {
    _disabled = v;
    // The editor may not have been created yet
    if (quillEditor != null) {
      quillEditor.enable(!v);
    }
  }

  final StreamController _blur = new StreamController.broadcast();
  @Output()
  Stream get blur => _blur.stream;

  final StreamController _input = new StreamController.broadcast();
  @Output()
  Stream get input => _input.stream;

  var _selectionChangeSub;
  var _textChangeSub;

  @override
  ngAfterContentInit() {
    quillEditor = new quill.QuillStatic(editor.nativeElement,
        new quill.QuillOptionsStatic(theme: 'snow', placeholder: placeholder));
    quillEditor.enable(!_disabled);
    quillEditor.pasteHTML(_initialValue);

    _textChangeSub = allowInterop(_onTextChange);
    _selectionChangeSub = allowInterop(_onSelectionChange);
    quillEditor.on('text-change', _textChangeSub);
    quillEditor.on('selection-change', _selectionChangeSub);
  }

  @override
  ngOnDestroy() {
    quillEditor.off('text-change', _textChangeSub);
    quillEditor.off('selection-change', _selectionChangeSub);

    // quill docs say no explicit destroy call is required.
  }

  /// Emitted when a user or API causes the selection to change, with a range representing the selection boundaries.
  /// A null range indicates selection loss (usually caused by loss of focus from the editor). You can also use this
  /// event as a focus change event by just checking if the emitted range is null or not.
  void _onSelectionChange(range, oldRange, String source) {
    if (range == null) {  // null range indicates blur event
      _blur.add(null);
    }
  }

  /// Emitted when the contents of Quill have changed. Details of the change, representation of the editor contents
  /// before the change, along with the source of the change are provided. The source will be "user" if it originates from the users
  void _onTextChange(delta, oldDelta, source) {
    _input.add(value);
  }
}

