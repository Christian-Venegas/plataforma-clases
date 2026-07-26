package com.academy.plataforma.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import javax.crypto.SecretKey;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

@Service
public class JwtService {

    // ===== Lee los valores del application.yml =====
    @Value("${app.jwt.secret}")
    private String secret;                        // 1. la clave secreta

    @Value("${app.jwt.expiration-ms}")
    private long expirationMs;                     // 2. cuánto dura el token

    // ===== Genera la clave a partir del secreto =====
    private SecretKey getSigningKey() {
        byte[] keyBytes = Decoders.BASE64.decode(secret);
        return Keys.hmacShaKeyFor(keyBytes);
    }

    // ===== CREAR un token para un usuario =====
    public String generarToken(String email, String rol) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("rol", rol);                    // guardamos el rol dentro del token

        return Jwts.builder()
                .claims(claims)                    // datos extra
                .subject(email)                    // el "dueño" del token (su email)
                .issuedAt(new Date())              // cuándo se creó
                .expiration(new Date(System.currentTimeMillis() + expirationMs))  // cuándo expira
                .signWith(getSigningKey())         // lo firma con la clave secreta
                .compact();                        // lo convierte en texto
    }

    // ===== EXTRAER el email del token =====
    public String extraerEmail(String token) {
        return extraerClaim(token, Claims::getSubject);
    }

    // ===== EXTRAER la fecha de expiración =====
    public Date extraerExpiracion(String token) {
        return extraerClaim(token, Claims::getExpiration);
    }

    // ===== Método genérico para leer cualquier dato del token =====
    public <T> T extraerClaim(String token, Function<Claims, T> resolver) {
        Claims claims = Jwts.parser()
                .verifyWith(getSigningKey())       // verifica la firma
                .build()
                .parseSignedClaims(token)
                .getPayload();
        return resolver.apply(claims);
    }

    // ===== ¿El token está vencido? =====
    public boolean estaExpirado(String token) {
        return extraerExpiracion(token).before(new Date());
    }

    // ===== ¿El token es válido para este usuario? =====
    public boolean esValido(String token, String email) {
        final String emailDelToken = extraerEmail(token);
        return emailDelToken.equals(email) && !estaExpirado(token);
    }
}