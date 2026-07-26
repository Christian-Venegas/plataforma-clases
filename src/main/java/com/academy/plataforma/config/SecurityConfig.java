package com.academy.plataforma.config;

import com.academy.plataforma.security.JwtAuthFilter;
import com.academy.plataforma.security.UsuarioDetailsService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.context.annotation.Configuration;

@Configuration
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;
    private final UsuarioDetailsService usuarioDetailsService;

    // ===== 1. Cifrado de contraseñas (BCrypt) =====
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    // ===== 2. Proveedor de autenticación (Spring Security 7) =====
    @Bean
    public DaoAuthenticationProvider authenticationProvider() {
        // ✅ Ahora el UserDetailsService va en el CONSTRUCTOR
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider(usuarioDetailsService);
        provider.setPasswordEncoder(passwordEncoder());
        return provider;
    }

    // ===== 3. Manager de autenticación (lo usará el login) =====
    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    // ===== 4. Las reglas de seguridad =====
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)            // API REST no usa CSRF
                .authorizeHttpRequests(auth -> auth
                        // Rutas PÚBLICAS (sin token)
                        .requestMatchers("/api/auth/**").permitAll()  // login y registro
                        .requestMatchers("/api/categorias").permitAll() // por ahora pública (temporal)
                        // Todo lo demás REQUIERE token
                        .anyRequest().authenticated()
                )
                // Sin sesiones: cada petición se valida con su token (stateless)
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authenticationProvider(authenticationProvider())
                // Nuestro guardia JWT se ejecuta ANTES del filtro estándar
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}