package com.academy.plataforma.security;

import com.academy.plataforma.common.enums.EstadoGenerico;
import com.academy.plataforma.usuario.entity.Usuario;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import java.util.Collection;
import java.util.List;

@RequiredArgsConstructor
public class UsuarioDetails implements UserDetails {

    private final Usuario usuario;                  // 1. envolvemos al usuario real

    // Permite acceder al usuario original cuando lo necesitemos
    public Usuario getUsuario() {
        return usuario;
    }

    // ===== 2. Los permisos/roles del usuario =====
    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        // Spring espera roles con prefijo "ROLE_"
        return List.of(new SimpleGrantedAuthority("ROLE_" + usuario.getRol().name()));
    }

    // ===== 3. La contraseña (hash) =====
    @Override
    public String getPassword() {
        return usuario.getPasswordHash();
    }

    // ===== 4. El "username" (usamos el email) =====
    @Override
    public String getUsername() {
        return usuario.getEmail();
    }

    // ===== 5. Estados de la cuenta =====
    @Override
    public boolean isAccountNonExpired() {
        return true;                                // la cuenta no expira
    }

    @Override
    public boolean isAccountNonLocked() {
        return usuario.getEstado() != EstadoGenerico.BLOQUEADO;   // bloqueada = no entra
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;                                // credenciales no expiran
    }

    @Override
    public boolean isEnabled() {
        return usuario.getEstado() == EstadoGenerico.ACTIVO;      // solo activos entran
    }
}