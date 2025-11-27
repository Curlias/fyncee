/// Configuración de Supabase
/// 
/// INSTRUCCIONES PARA OBTENER TUS CREDENCIALES:
/// 1. Ve a https://supabase.com y crea una cuenta (gratis)
/// 2. Crea un nuevo proyecto
/// 3. Ve a Settings > API
/// 4. Copia la URL y la anon/public key
/// 5. Reemplaza los valores abajo

class SupabaseConfig {
  // URL de tu proyecto Supabase
  static const String supabaseUrl = 'https://unzkvocrbbqnlyqknufc.supabase.co';

  // Anon key (clave pública - segura para usar en la app)
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVuemt2b2NyYmJxbmx5cWtudWZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2MjcyNTQsImV4cCI6MjA3NjIwMzI1NH0.IEag74iMPRbGfHaY553TmNZ6WHDTIYYxjgc1vFo_CUU';

  // Verificar que las credenciales estén configuradas
  static bool get isConfigured =>
      supabaseUrl != 'TU_SUPABASE_URL_AQUI' &&
      supabaseAnonKey != 'TU_SUPABASE_ANON_KEY_AQUI';
}

