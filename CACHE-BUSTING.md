# 🧹 Cache Busting — Niido Home Landing Page

## ¿Qué es el cache busting?

Los navegadores (especialmente en **Android / Chrome Mobile**) guardan copias locales de los
archivos `.js` y `.css` para no tener que descargarlos de nuevo cada vez que entras a la página.
Esto es bueno para la velocidad, pero puede causar que los usuarios vean una **versión vieja**
del sitio después de que hagas cambios y publiques.

---

## 🚨 Problema que ocurrió

- Se eliminó el **auto-avance del carrusel** en `main.js`
- En **PC** funcionó inmediatamente ✅
- En **Android** seguía avanzando solo ❌ → el teléfono usaba el `main.js` viejo del caché

---

## ✅ Solución aplicada: parámetro de versión

En `index.html`, el enlace al script se cambió así:

```html
<!-- ANTES (el navegador usa el caché sin importar los cambios) -->
<script src="assets/js/main.js" defer></script>

<!-- DESPUÉS (el ?v=2 fuerza al navegador a descargar el archivo nuevo) -->
<script src="assets/js/main.js?v=2" defer></script>
```

El `?v=2` hace que el navegador piense que es un archivo diferente, obligándolo a
descargarlo fresco desde el servidor.

---

## 📋 ¿Cuándo debes hacer esto?

Debes **incrementar el número de versión** cada vez que hagas cambios importantes en:

| Archivo | Línea en `index.html` | Ejemplo |
|---|---|---|
| `assets/js/main.js` | ~línea 871 | `main.js?v=3` |
| `assets/css/styles.css` | buscar el `<link>` del CSS | `styles.css?v=2` |

---

## 🔄 Pasos para actualizar la versión

1. Abre `index.html`
2. Busca la línea del script o del CSS que modificaste
3. Incrementa el número: `?v=2` → `?v=3` → `?v=4`, etc.
4. Guarda el archivo
5. Haz `git add`, `git commit` y `git push`

### Ejemplo de commit:

```bash
git add -A
git commit -m "fix: cache bust main.js v3 tras actualizar carrusel"
git push origin main
```

---

## 💡 También puedes usar la fecha como versión

Si prefieres algo más descriptivo:

```html
<script src="assets/js/main.js?v=20260303" defer></script>
```

Esto es útil para saber exactamente cuándo fue la última actualización.

---

> **Regla de oro:** Si haces un cambio en JS o CSS y los usuarios siguen viendo el
> comportamiento anterior en móvil, lo primero que debes revisar es si actualizaste
> el número de versión `?v=` en `index.html`.
