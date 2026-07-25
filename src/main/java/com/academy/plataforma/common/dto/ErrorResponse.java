package com.academy.plataforma.common.dto;


import lombok.*;

import java.time.LocalDateTime;
import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ErrorResponse {
    private LocalDateTime timestamp; // cuándo ocurrió
    private int status; // código HTTP (400, 404, 500...)
    private String error; // tipo de error
    private String message; // mensaje claro para el usuario
    private String path; // en qué endpoint pasó
    private Map<String, String> validationErrors; // errores de validación (si hay)
}
