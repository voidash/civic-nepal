// GlobalUsings.cs — Resolves implicit using conflicts in WPF + WinForms projects.
//
// Context: NagarikPatro.csproj has UseWPF=true, UseWindowsForms=true, ImplicitUsings=enable.
// The WPF build temp project (*_wpftmp.csproj) inherits the WPF/WinForms SDK implicit usings
// but NOT the base C# implicit usings (System.IO etc.), causing two classes of failures:
//   1. File / Path / Directory not found (System.IO missing in wpftmp)
//   2. Color / Brush / Application etc. ambiguous (System.Drawing vs System.Windows.Media;
//      System.Windows.Forms vs System.Windows)
//
// This file applies to both the main project and the wpftmp project.

// Restore base C# implicit usings that are absent in the wpftmp:
global using System.IO;

// Disambiguate: prefer WPF / System.Windows types over WinForms / System.Drawing equivalents.
global using Application       = System.Windows.Application;
global using Brush             = System.Windows.Media.Brush;
global using Brushes           = System.Windows.Media.Brushes;
global using Color             = System.Windows.Media.Color;
global using Cursors           = System.Windows.Input.Cursors;
global using FontFamily        = System.Windows.Media.FontFamily;
global using HorizontalAlignment = System.Windows.HorizontalAlignment;
global using Orientation       = System.Windows.Controls.Orientation;
global using SystemColors      = System.Windows.SystemColors;
