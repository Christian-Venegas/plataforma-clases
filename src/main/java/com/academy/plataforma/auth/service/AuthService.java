package com.academy.plataforma.auth.service;

import com.academy.plataforma.auth.dto.*;
import com.academy.plataforma.common.enums.EstadoGenerico;
import com.academy.plataforma.common.enums.RolUsuario;
import com.academy.plataforma.security.JwtService;
import com.academy.plataforma.tenant.entity.Tenant;
import com.academy.plataforma.tenant.repository.TenantRepository;
import com.academy.plataforma.usuario.entity.Usuario;
import com.academy.plataforma.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UsuarioRepository usuarioRepository;
    private final TenantRepository tenantRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    // ===== REGISTRO =====
    @Transactional
    public AuthResponse registrar(RegisterRequest request) {
        // 1. Verificar que el email no exista
        if (usuarioRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Ya existe un usuario con ese email");
        }

        // 2. Buscar el tenant por defecto (id = 1)
        Tenant tenant = tenantRepository.findById(1L)
                .orElseThrow(() -> new IllegalArgumentException("No existe el tenant por defecto"));

        // 3. Crear el usuario con la contraseña CIFRADA
        Usuario usuario = Usuario.builder()
                .tenant(tenant)
                .nombre(request.getNombre())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))  // 🔐 BCrypt
                .rol(RolUsuario.ALUMNO)                    // por defecto alumno
                .emailVerificado(false)
                .estado(EstadoGenerico.ACTIVO)
                .build();

        usuarioRepository.save(usuario);

        // 4. Generar y devolver el token
        String token = jwtService.generarToken(usuario.getEmail(), usuario.getRol().name());
        return construirRespuesta(usuario, token);
    }

    // ===== LOGIN =====
    public AuthResponse login(LoginRequest request) {
        // 1. Verificar email + contraseña (Spring lo hace por nosotros)
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        // 2. Si pasó, buscar el usuario y generar token
        Usuario usuario = usuarioRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado"));

        String token = jwtService.generarToken(usuario.getEmail(), usuario.getRol().name());
        return construirRespuesta(usuario, token);
    }

    // ===== Helper: construir la respuesta =====
    private AuthResponse construirRespuesta(Usuario usuario, String token) {
        return AuthResponse.builder()
                .token(token)
                .tipo("Bearer")
                .nombre(usuario.getNombre())
                .email(usuario.getEmail())
                .rol(usuario.getRol().name())
                .build();
    }
}