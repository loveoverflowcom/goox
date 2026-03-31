use image::ImageFormat;
use std::{fmt, path::Path};

#[derive(Debug)]
pub enum ImageError {
    FileNotFound(String),
    UnsupportedFormat(String),
    DecodeFailed(String),
    RenderFailed(String),
}

impl fmt::Display for ImageError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ImageError::FileNotFound(path) => write!(f, "file not found: {path}"),
            ImageError::UnsupportedFormat(msg) => write!(f, "unsupported image format: {msg}"),
            ImageError::DecodeFailed(msg) => write!(f, "image decode failed: {msg}"),
            ImageError::RenderFailed(msg) => write!(f, "image render failed: {msg}"),
        }
    }
}

#[derive(Debug, Clone)]
pub struct ImageInfo {
    pub format: String,
    pub width: u32,
    pub height: u32,
    pub size_bytes: u64,
}

pub struct RgbaImageFrame {
    pub data: Vec<u8>,
    pub width: u32,
    pub height: u32,
}

pub struct ImageRenderer;

impl ImageRenderer {
    pub fn new() -> Self {
        Self
    }

    pub fn get_info(&self, file_path: &str) -> Result<ImageInfo, ImageError> {
        let bytes = self.read_bytes(file_path)?;
        let format = self.detect_format(file_path, &bytes)?;

        if is_svg(file_path, &bytes) {
            let (width, height) = svg_dimensions(&bytes)?;
            return Ok(ImageInfo {
                format: "svg".to_string(),
                width,
                height,
                size_bytes: bytes.len() as u64,
            });
        }

        let image = image::load_from_memory_with_format(&bytes, format)
            .map_err(|error| ImageError::DecodeFailed(error.to_string()))?;

        Ok(ImageInfo {
            format: format_name(&format),
            width: image.width(),
            height: image.height(),
            size_bytes: bytes.len() as u64,
        })
    }

    pub fn render(
        &self,
        file_path: &str,
        width: u32,
        height: u32,
    ) -> Result<RgbaImageFrame, ImageError> {
        let bytes = self.read_bytes(file_path)?;

        if is_svg(file_path, &bytes) {
            let rendered = render_svg(&bytes, width, height)?;
            return Ok(RgbaImageFrame {
                data: rendered,
                width,
                height,
            });
        }

        let format = self.detect_format(file_path, &bytes)?;
        let image = image::load_from_memory_with_format(&bytes, format)
            .map_err(|error| ImageError::DecodeFailed(error.to_string()))?;
        let resized = image.resize(width, height, image::imageops::FilterType::Lanczos3);

        Ok(RgbaImageFrame {
            data: resized.to_rgba8().into_raw(),
            width,
            height,
        })
    }

    fn read_bytes(&self, file_path: &str) -> Result<Vec<u8>, ImageError> {
        if !Path::new(file_path).exists() {
            return Err(ImageError::FileNotFound(file_path.to_string()));
        }

        std::fs::read(file_path).map_err(|error| ImageError::DecodeFailed(error.to_string()))
    }

    fn detect_format(&self, file_path: &str, bytes: &[u8]) -> Result<ImageFormat, ImageError> {
        if let Ok(format) = image::guess_format(bytes) {
            return Ok(format);
        }

        let ext = Path::new(file_path)
            .extension()
            .and_then(|ext| ext.to_str())
            .unwrap_or("")
            .to_lowercase();

        match ext.as_str() {
            "png" => Ok(ImageFormat::Png),
            "jpg" | "jpeg" => Ok(ImageFormat::Jpeg),
            "gif" => Ok(ImageFormat::Gif),
            "webp" => Ok(ImageFormat::WebP),
            "bmp" => Ok(ImageFormat::Bmp),
            "ico" => Ok(ImageFormat::Ico),
            "tif" | "tiff" => Ok(ImageFormat::Tiff),
            "avif" => Ok(ImageFormat::Avif),
            _ if is_svg(file_path, bytes) => Ok(ImageFormat::Png),
            _ => Err(ImageError::UnsupportedFormat(ext)),
        }
    }
}

fn is_svg(file_path: &str, bytes: &[u8]) -> bool {
    let ext = Path::new(file_path)
        .extension()
        .and_then(|ext| ext.to_str())
        .unwrap_or("")
        .to_lowercase();

    ext == "svg" || bytes.starts_with(b"<svg") || bytes.windows(4).any(|w| w == b"<svg")
}

fn render_svg(svg_bytes: &[u8], width: u32, height: u32) -> Result<Vec<u8>, ImageError> {
    let opt = usvg::Options::default();
    let tree = usvg::Tree::from_data(svg_bytes, &opt)
        .map_err(|error| ImageError::DecodeFailed(error.to_string()))?;
    let mut pixmap = tiny_skia::Pixmap::new(width, height)
        .ok_or_else(|| ImageError::RenderFailed("failed to allocate svg pixmap".to_string()))?;
    let mut pm = pixmap.as_mut();
    let size = tree.size();
    let scale_x = width as f32 / size.width();
    let scale_y = height as f32 / size.height();
    let transform = tiny_skia::Transform::from_scale(scale_x, scale_y);
    resvg::render(&tree, transform, &mut pm);
    Ok(pixmap.take())
}

fn svg_dimensions(svg_bytes: &[u8]) -> Result<(u32, u32), ImageError> {
    let opt = usvg::Options::default();
    let tree = usvg::Tree::from_data(svg_bytes, &opt)
        .map_err(|error| ImageError::DecodeFailed(error.to_string()))?;
    let size = tree.size().to_int_size();
    Ok((size.width(), size.height()))
}

fn format_name(format: &ImageFormat) -> String {
    match format {
        ImageFormat::Png => "png",
        ImageFormat::Jpeg => "jpeg",
        ImageFormat::Gif => "gif",
        ImageFormat::WebP => "webp",
        ImageFormat::Bmp => "bmp",
        ImageFormat::Tiff => "tiff",
        ImageFormat::Tga => "tga",
        ImageFormat::Dds => "dds",
        ImageFormat::Farbfeld => "farbfeld",
        ImageFormat::Avif => "avif",
        ImageFormat::Qoi => "qoi",
        _ => "image",
    }
    .to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn svg_detection_matches_extension() {
        assert!(is_svg("icon.svg", b"not really svg"));
    }

    #[test]
    fn svg_detection_matches_bytes() {
        assert!(is_svg("icon.bin", b"<svg viewBox=\"0 0 1 1\"></svg>"));
    }
}
