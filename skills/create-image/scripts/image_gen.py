from __future__ import annotations

import argparse
import os
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Final

from dotenv import dotenv_values
from google import genai
from google.genai import types

MODEL_PRO: Final[str] = "gemini-3-pro-image-preview"
MODEL_FAST: Final[str] = "gemini-3.1-flash-image-preview"
DEFAULT_OUTPUT: Final[Path] = Path("output.png")
API_KEY_ENV_VARS: Final[tuple[str, str]] = ("GEMINI_API_KEY", "GOOGLE_API_KEY")


@dataclass(frozen=True, slots=True)
class CliArgs:
    prompt: str
    output: Path
    fast: bool
    aspect_ratio: str | None
    image_size: str | None
    env_file: Path


def resolve_output_path(path: Path) -> Path:
    if path.suffix:
        return path
    return path.with_suffix(".png")


def parse_args(argv: Sequence[str] | None = None) -> CliArgs:
    parser = argparse.ArgumentParser(
        description="Generate an image using Gemini Nano Banana (Pro or Fast)."
    )
    parser.add_argument("prompt", help="Prompt text for image generation.")
    parser.add_argument(
        "-o",
        "--output",
        default=str(DEFAULT_OUTPUT),
        help="Output file path. If no extension is provided, .png is used.",
    )
    parser.add_argument(
        "--fast",
        action="store_true",
        default=False,
        help="Use Nano Banana Fast (gemini-2.5-flash-image) instead of Pro.",
    )
    parser.add_argument(
        "--aspect-ratio",
        default=None,
        help='Optional aspect ratio (example: "16:9").',
    )
    parser.add_argument(
        "--image-size",
        default=None,
        help='Optional image size supported by model (example: "2K").',
    )
    parser.add_argument(
        "--env-file",
        default=".env",
        help="Path to .env file containing GEMINI_API_KEY or GOOGLE_API_KEY.",
    )
    parsed = parser.parse_args(argv)
    return CliArgs(
        prompt=parsed.prompt,
        output=resolve_output_path(Path(parsed.output)),
        fast=parsed.fast,
        aspect_ratio=parsed.aspect_ratio,
        image_size=parsed.image_size,
        env_file=Path(parsed.env_file),
    )


def load_api_key(env_file: Path) -> str:
    env_values = dotenv_values(env_file) if env_file.exists() else {}

    for env_name in API_KEY_ENV_VARS:
        file_value = env_values.get(env_name)
        if file_value is not None and file_value.strip():
            return file_value.strip()

    for env_name in API_KEY_ENV_VARS:
        shell_value = os.getenv(env_name)
        if shell_value is not None and shell_value.strip():
            return shell_value.strip()

    accepted = ", ".join(API_KEY_ENV_VARS)
    raise RuntimeError(
        f"Missing API key. Set one of {accepted} in {env_file} or as environment variables."
    )


def build_generation_config(
    aspect_ratio: str | None, image_size: str | None
) -> types.GenerateContentConfig:
    image_config = types.ImageConfig(
        aspect_ratio=aspect_ratio,
        image_size=image_size,
    )
    return types.GenerateContentConfig(
        response_modalities=[types.Modality.IMAGE],
        image_config=image_config,
    )


def extract_image_bytes(response: types.GenerateContentResponse) -> bytes:
    candidates = response.candidates or []
    for candidate in candidates:
        content = candidate.content
        if content is None:
            continue
        parts = content.parts or []
        for part in parts:
            inline_data = part.inline_data
            if inline_data is None or inline_data.data is None:
                continue
            return inline_data.data

    raise RuntimeError("No image data found in Gemini response.")


def generate_image(
    *,
    api_key: str,
    prompt: str,
    output: Path,
    fast: bool = False,
    aspect_ratio: str | None = None,
    image_size: str | None = None,
) -> Path:
    model = MODEL_FAST if fast else MODEL_PRO
    client = genai.Client(api_key=api_key)
    response = client.models.generate_content(
        model=model,
        contents=[prompt],
        config=build_generation_config(aspect_ratio, image_size),
    )

    image_bytes = extract_image_bytes(response)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(image_bytes)
    return output


def run(args: CliArgs) -> Path:
    api_key = load_api_key(args.env_file)
    return generate_image(
        api_key=api_key,
        prompt=args.prompt,
        output=args.output,
        fast=args.fast,
        aspect_ratio=args.aspect_ratio,
        image_size=args.image_size,
    )


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        output_path = run(args)
    except Exception as exc:  # noqa: BLE001
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    print(f"Image saved to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
