# Tulip Method Separators

  **Tulip Method Separators** is a lightweight Delphi IDE (RAD Studio) plugin designed to enhance source code readability by
  drawing subtle horizontal separators between methods, classes, and records directly within the code editor.

  By providing clear visual boundaries, this plugin helps developers navigate long units more efficiently, making the
  structure of the code instantly recognizable.
  
<a href="https://www.buymeacoffee.com/samerassil" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me a Coffee" style="height: 60px !important;width: 217px !important;" ></a>  

<img width="1182" height="914" alt="Screenshot 2026-04-04 at 00 59 45" src="https://github.com/user-attachments/assets/c5970243-e8a0-4483-8888-f979007d8faf" />

  ---

  ✨ Features

   * Visual Method Separation: Automatically draws dotted horizontal lines between procedures, functions, constructors,
     and destructors.
   * Structural Awareness: Identifies and separates class, record, initialization, and finalization blocks.
   * Smart Context Detection: Intelligently identifies the implementation section to ensure separators are only drawn
     where they provide the most value, avoiding clutter in the interface section.
   * Theme-Aware & Custom Colors: Dynamically adjusts separator color based on your IDE's background theme (Light or Dark) using HLS luminance calculations, or choose your own custom color with contrast protection.
   * Configurable Options: Choose line colors, styles (Dotted, Dashed, Solid), and section scope via **Tools > Tulip Method Separators Settings...**.
   * Native ToolsAPI Integration: Built using the standard Delphi Open Tools API (INTACodeEditorEvents) for seamless performance and stability.

  🚀 Installation

   1. Clone this repository to your local machine.
   2. Open the TulipMethodSeparators.dproj project in RAD Studio.
   3. Right-click on the project in the Project Manager and select Build.
   4. Right-click again and select Install.
   5. The plugin is now active! Open any .pas file to see the separators.
   6. (Optional) Customize colors and line styles under **Tools > Tulip Method Separators Settings...**.

  🛠️ Technical Overview

  📝 Requirements

   * Embarcadero RAD Studio.
   * Delphi 11.x and above ( Tested on Delphi 13.1 ). 

  🤝 Contributing

  Contributions are welcome! If you have ideas for new features, better styling, or bug fixes, feel free to open an
  issue or submit a pull request.

  ---

  Developed with ❤️ for the Delphi Community.
