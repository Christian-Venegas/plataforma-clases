package com.academy.plataforma.tenant.repository;

import com.academy.plataforma.tenant.entity.Tenant;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TenantRepository extends JpaRepository<Tenant, Long> {
}
