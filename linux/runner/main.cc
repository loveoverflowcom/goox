#include <native_splash_screen_linux/native_splash_screen_linux_plugin.h>
#include "my_application.h"

int main(int argc, char** argv) {
  // Initialize GTK first
  gtk_init(&argc, &argv);

  // Show the splash screen before the app starts
  show_splash_screen();

  // Then initialize and run the application as normal
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
