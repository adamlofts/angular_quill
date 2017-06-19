# Angular Quill

An angular dart component for the Quill rich text editor

## [See it in action](https://adamlofts.github.io/angular_quill/build/example/index.html) 

Visit https://adamlofts.github.io/angular_quill/build/example/index.html

And view the corresponding [example source code](https://github.com/adamlofts/angular_quill/blob/master/example/app_component.html). 

## Usage

Add the dependency to pub:

```yaml
dependencies:
  angular_quill: ^0.0.1
```

Add the component to your template

```html
<my-app>
    <quill
            [(ngModel)]="html"
            placeholder="Write something..."
            (blur)="blur()"
            (input)="input()"
    ></quill>
</my-app>

```

Add `quillDirectives` to the directives on your app component

```dart
@Component(
  selector: 'my-app',
  templateUrl: 'app_component.html',
  directives: const [COMMON_DIRECTIVES, quillDirectives],
)
class AppComponent {}

```