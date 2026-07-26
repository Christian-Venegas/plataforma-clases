package com.academy.plataforma.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {   // 1. se ejecuta 1 vez por petición

    private final JwtService jwtService;
    private final UsuarioDetailsService usuarioDetailsService;

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain) throws ServletException, IOException {

        // 2. Buscar el token en el header "Authorization"
        final String authHeader = request.getHeader("Authorization");

        // 3. Si no hay token o no empieza con "Bearer ", seguir sin autenticar
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        // 4. Extraer el token (quitar el "Bearer " del inicio)
        final String token = authHeader.substring(7);
        final String email = jwtService.extraerEmail(token);

        // 5. Si hay email y el usuario aún no está autenticado en este request
        if (email != null && SecurityContextHolder.getContext().getAuthentication() == null) {

            UserDetails userDetails = usuarioDetailsService.loadUserByUsername(email);

            // 6. Si el token es válido, autenticar al usuario
            if (jwtService.esValido(token, userDetails.getUsername())) {
                UsernamePasswordAuthenticationToken authToken =
                        new UsernamePasswordAuthenticationToken(
                                userDetails,
                                null,
                                userDetails.getAuthorities());   // sus roles
                authToken.setDetails(
                        new WebAuthenticationDetailsSource().buildDetails(request));
                // 7. Guardar al usuario como "autenticado" en este request
                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
        }

        filterChain.doFilter(request, response);   // 8. continuar con la petición
    }
}