package com.academy.plataforma.usuario.entity;

import com.academy.plataforma.common.enums.EstadoGenerico;
import com.academy.plataforma.common.enums.RolUsuario;
import com.academy.plataforma.tenant.entity.Tenant;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;
import java.time.LocalDateTime;

@Entity
@Table(
        name = "usuarios",
        uniqueConstraints = @UniqueConstraint(          // refleja tu UNIQUE (id_tenants, email)
                name = "uq_usuarios_email_tenant",
                columnNames = {"id_tenants", "email"}
        )
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_usuarios")
    private Long idUsuarios;

    // ===== RELACIÓN: muchos usuarios -> un tenant =====
    @ManyToOne(fetch = FetchType.LAZY)              // 1. Muchos usuarios pertenecen a un tenant
    @JoinColumn(                                    // 2. Esta es la columna FK
            name = "id_tenants",                        //    nombre de la columna en la tabla usuarios
            nullable = false,
            foreignKey = @ForeignKey(name = "fk_usuarios_tenants")
    )
    private Tenant tenant;                          // 3. Guardamos el objeto Tenant completo

    @Column(name = "nombre", nullable = false, length = 150)
    private String nombre;

    @Column(name = "email", nullable = false, length = 180)
    private String email;

    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;                    // 4. Nunca contraseña en texto plano

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "rol", nullable = false, columnDefinition = "rol_usuario")
    private RolUsuario rol;

    @Column(name = "foto_url", length = 500)
    private String fotoUrl;

    @Column(name = "email_verificado", nullable = false)
    private Boolean emailVerificado;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "estado", nullable = false, columnDefinition = "estado_generico")
    private EstadoGenerico estado;

    @CreationTimestamp
    @Column(name = "creado_en", updatable = false)
    private LocalDateTime creadoEn;

    @UpdateTimestamp
    @Column(name = "actualizado_en")
    private LocalDateTime actualizadoEn;
}