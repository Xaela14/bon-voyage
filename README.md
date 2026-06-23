# Bon Voyage ✈️

Planificador de viajes colaborativo. HTML/CSS/JS plano + [Supabase](https://supabase.com) (plan gratuito, sin tarjeta).

## Setup (una sola vez)

1. Entrá a [supabase.com](https://supabase.com) con tu cuenta y creá un **proyecto nuevo** llamado `bon-voyage` (plan Free).
2. Una vez creado, abrí **SQL Editor** → pegá todo el contenido de [`schema.sql`](schema.sql) → **Run**.
3. Abrí **Project Settings → API** y copiá:
   - **Project URL**
   - **anon / publishable key**
4. Pegalos en [`config.js`](config.js), reemplazando `TU_SUPABASE_URL_AQUI` y `TU_SUPABASE_ANON_KEY_AQUI`.
5. (Opcional) En **Authentication → Providers**, si no querés que pida confirmación de email para probar rápido, podés desactivar "Confirm email" en **Authentication → Settings**.

## Probar localmente

Abrí `index.html` directo en el navegador, o servilo con cualquier servidor estático (ej. extensión "Live Server" de VS Code).

## Publicar gratis (GitHub Pages)

1. `git remote add origin <url-de-tu-repo-en-GitHub>`
2. `git push -u origin main`
3. En GitHub: Settings → Pages → Deploy from branch → `main` / `/ (root)`.

## Qué incluye el MVP

- Registro/login (Supabase Auth, email + contraseña)
- Crear viaje → código de 5 dígitos para que otros se unan
- Viajes con uno o varios países (lista completa de países ISO)
- Presupuesto común del viaje + presupuesto personal por viajero
- Categorías: vuelos, hospedaje, comidas, visitas
- Cada viajero decide si comparte su presupuesto personal con el resto
- Vínculo opcional con La Canasta (guarda el email vinculado; la sincronización de datos real es la próxima fase)

## Próximas fases

- Integración real con Google Calendar
- Sincronizar gastos de viaje con La Canasta
- Selector de ciudades (hoy es texto libre)
- Conversión de monedas automática para totales del viaje
