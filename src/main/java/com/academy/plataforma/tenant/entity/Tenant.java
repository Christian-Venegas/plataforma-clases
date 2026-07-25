package com.academy.plataforma.tenant.entity;

import com.academy.plataforma.common.enums.EstadoGenerico;
import com.academy.plataforma.common.enums.TipoTenant;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;
import java.time.LocalDateTime;

@Entity
@Table(name = "tenants")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Tenant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_tenants")
    private Long idTenants;

    @Column(name = "nombre", nullable = false, length = 150)
    private String nombre;

    // ===== ENUM de Postgres: tipo_tenant =====
    @Enumerated(EnumType.STRING)                     // 1. Guarda el texto ('PROFESOR'), no un número
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)               // 2. Le dice a Hibernate que es un ENUM nativo de Postgres
    @Column(name = "tipo", nullable = false, columnDefinition = "tipo_tenant")  // 3. El tipo exacto del SQL
    private TipoTenant tipo;

    @Column(name = "logo_url", length = 500)
    private String logoUrl;

    // ===== Campo JSONB =====
    @JdbcTypeCode(SqlTypes.JSON)                     // 4. Mapea a JSONB de Postgres
    @Column(name = "config", columnDefinition = "jsonb")
    private String config;

    // ===== ENUM de Postgres: estado_generico =====
    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "estado", nullable = false, columnDefinition = "estado_generico")
    private EstadoGenerico estado;

    @CreationTimestamp
    @Column(name = "creado_en", updatable = false)
    private LocalDateTime creadoEn;

    @UpdateTimestamp                                 // 5. Se actualiza solo en cada UPDATE
    @Column(name = "actualizado_en")
    private LocalDateTime actualizadoEn;
}