package com.academy.plataforma.auth.dto;


import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthResponse {
        private String token;
        private String tipo; // "Bearer"
        private String nombre;
        private String email;

        private String rol;
}
