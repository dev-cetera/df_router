<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img align="right" src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="48"></a>
<a href="https://discord.gg/gEQ8y2nfyX" target="_blank"><img align="right" src="https://raw.githubusercontent.com/dev-cetera/resources/refs/heads/main/assets/discord_icon/discord_icon.svg" height="48"></a>

Dart & Flutter Packages by dev-cetera.com & contributors.

[![pub package](https://img.shields.io/pub/v/df_router.svg)](https://pub.dev/packages/df_router)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/df_router/main/LICENSE)

## Summary

A package that provides a practical Debouncer for optimizing performance by controlling the frequency of function calls in response to rapid events.

For a full feature set, please refer to the [API reference](https://pub.dev/documentation/df_router/).

## Usage Example

```dart
// Create a debouncer to automatically save a form to the database after some delay.
late final _autosave = Debouncer(
  delay: const Duration(milliseconds: 500),
   onStart: () {
      print('Saving form...');
    },
  onWaited: () {
    final name = _nameController.text;
    final email = _emailController.text;
    print('Form saved to database: {"name": "$name", "email": "$email"}');
  },
  onCall: () {
    print('Form changed!');
  },
);

// Tigger the autosave when the form changes.
TextField(
  controller: _emailController,
  decoration: const InputDecoration(
    labelText: 'Email:',
   ),
  onChanged: (_) => _autosave(),
),

// Immediately save the form to the database when the page is closed.
@override
void dispose() {
  _autosave.finalize();
  super.dispose();
}
```

---

## Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### Ways you can contribute

- **Buy me a coffee:** If you'd like to support the project financially, consider [buying me a coffee](https://www.buymeacoffee.com/dev_cetera). Your support helps cover the costs of development and keeps the project growing.
- **Find us on Discord:** Feel free to ask questions and engage with the community here: https://discord.gg/gEQ8y2nfyX.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Help others:** Engage with other users by offering advice, solutions, or troubleshooting assistance.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

### We drink a lot of coffee...

If you're enjoying this package and find it valuable, consider showing your appreciation with a small donation. Every bit helps in supporting future development. You can donate here: https://www.buymeacoffee.com/dev_cetera

<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="40"></a>

## License

This project is released under the MIT License. See [LICENSE](https://raw.githubusercontent.com/dev-cetera/df_router/main/LICENSE) for more information.
