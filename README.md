# Tulip Method Separators

  **Tulip Method Separators** is a lightweight Delphi IDE (RAD Studio) plugin designed to enhance source code readability by
  drawing subtle horizontal separators between methods, classes, and records directly within the code editor.

  By providing clear visual boundaries, this plugin helps developers navigate long units more efficiently, making the
  structure of the code instantly recognizable.

  ---

  ✨ Features

   * Visual Method Separation: Automatically draws dotted horizontal lines between procedures, functions, constructors,
     and destructors.
   * Structural Awareness: Identifies and separates class, record, initialization, and finalization blocks.
   * Smart Context Detection: Intelligently identifies the implementation section to ensure separators are only drawn
     where they provide the most value, avoiding clutter in the interface section.
   * Theme-Aware Coloring: Dynamically adjusts the separator line color based on your IDE’s background theme (Light or
     Dark) using HLS-based luminance calculations.
   * Native ToolsAPI Integration: Built using the standard Delphi Open Tools API (INTACodeEditorEvents) for seamless
     performance and stability.

  🚀 Installation

   1. Clone this repository to your local machine.
   2. Open the TulipMethodSeparators.dproj project in RAD Studio.
   3. Right-click on the project in the Project Manager and select Build.
   4. Right-click again and select Install.
   5. The plugin is now active! Open any .pas file to see the separators.

  🛠️ Technical Overview

  📝 Requirements

   * Embarcadero RAD Studio.
   * Delphi 11.x and ubove ( Tested on Delphi 13.1 ). 

  🤝 Contributing

  Contributions are welcome! If you have ideas for new features, better styling, or bug fixes, feel free to open an
  issue or submit a pull request.

  ---

  Developed with ❤️ for the Delphi Community.
