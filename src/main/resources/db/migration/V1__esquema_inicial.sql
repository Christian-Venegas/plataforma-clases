-- =====================================================================
--  PLATAFORMA DE CURSOS + CLASES EN VIVO  —  ESQUEMA POSTGRESQL
--  Autor: Christian Venegas Y Fiorella Diaz
--  Motor:  PostgreSQL 14+
--  Convencion: PK/FK con nombre completo (id_cursos, id_alumnos...).
--              Toda tabla de negocio incluye id_tenants (multi-tenant).
--  Orden: las tablas se crean respetando sus dependencias (FK).
-- =====================================================================

-- =====================================================================
--  0) LIMPIEZA OPCIONAL (comentar en produccion)
-- =====================================================================
-- DROP SCHEMA public CASCADE;
-- CREATE SCHEMA public;

-- =====================================================================
--  1) TIPOS ENUM (estados y categorizaciones controladas)
-- =====================================================================
CREATE TYPE rol_usuario        AS ENUM ('ALUMNO', 'PROFESOR', 'ADMIN', 'SUPERADMIN');
CREATE TYPE estado_generico    AS ENUM ('ACTIVO', 'INACTIVO', 'BLOQUEADO');
CREATE TYPE tipo_tenant        AS ENUM ('ACADEMIA', 'PROFESOR');
CREATE TYPE nivel_curso        AS ENUM ('PRINCIPIANTE', 'INTERMEDIO', 'AVANZADO');
CREATE TYPE estado_curso       AS ENUM ('BORRADOR', 'EN_REVISION', 'PUBLICADO', 'ARCHIVADO');
CREATE TYPE tipo_leccion       AS ENUM ('VIDEO', 'TEXTO', 'QUIZ', 'CODIGO', 'PDF');
CREATE TYPE estado_matricula   AS ENUM ('ACTIVA', 'COMPLETADA', 'CANCELADA', 'VENCIDA');
CREATE TYPE tipo_pregunta      AS ENUM ('OPCION_UNICA', 'OPCION_MULTIPLE', 'VERDADERO_FALSO');
CREATE TYPE estado_clase_vivo  AS ENUM ('PROGRAMADA', 'EN_VIVO', 'FINALIZADA', 'CANCELADA');
CREATE TYPE metodo_pago        AS ENUM ('TARJETA', 'YAPE', 'PLIN', 'MERCADO_PAGO', 'PAYPAL', 'TRANSFERENCIA', 'GRATIS');
CREATE TYPE estado_pago        AS ENUM ('PENDIENTE', 'PAGADO', 'FALLIDO', 'REEMBOLSADO');
CREATE TYPE plan_suscripcion   AS ENUM ('MENSUAL', 'ANUAL', 'PRUEBA');
CREATE TYPE estado_suscripcion AS ENUM ('ACTIVA', 'CANCELADA', 'VENCIDA', 'PRUEBA');
CREATE TYPE tipo_gamificacion  AS ENUM ('XP', 'BADGE', 'RACHA');

-- =====================================================================
--  2) TABLAS BASE (sin dependencias)
-- =====================================================================

-- 2.1 Tenants (academia o profesor independiente)
CREATE TABLE tenants (
    id_tenants     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre         VARCHAR(150) NOT NULL,
    tipo           tipo_tenant  NOT NULL DEFAULT 'PROFESOR',
    logo_url       VARCHAR(500),
    config         JSONB        NOT NULL DEFAULT '{}'::jsonb,
    estado         estado_generico NOT NULL DEFAULT 'ACTIVO',
    creado_en      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    actualizado_en TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- 2.2 Categorias de cursos
CREATE TABLE categorias (
    id_categorias  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL UNIQUE,
    descripcion    VARCHAR(300),
    icono          VARCHAR(100),
    creado_en      TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- =====================================================================
--  3) USUARIOS Y PERFILES
-- =====================================================================

-- 3.1 Usuarios (identidad y credenciales)
CREATE TABLE usuarios (
    id_usuarios    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tenants     BIGINT       NOT NULL,
    nombre         VARCHAR(150) NOT NULL,
    email          VARCHAR(180) NOT NULL,
    password_hash  VARCHAR(255) NOT NULL,          -- BCrypt/Argon2, nunca texto plano
    rol            rol_usuario  NOT NULL DEFAULT 'ALUMNO',
    foto_url       VARCHAR(500),
    email_verificado BOOLEAN    NOT NULL DEFAULT FALSE,
    estado         estado_generico NOT NULL DEFAULT 'ACTIVO',
    creado_en      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    actualizado_en TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_usuarios_tenants
        FOREIGN KEY (id_tenants) REFERENCES tenants (id_tenants)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- El email es unico por tenant (permite mismo correo en tenants distintos)
    CONSTRAINT uq_usuarios_email_tenant UNIQUE (id_tenants, email)
);

-- 3.2 Perfil de profesor (extiende a usuarios con rol PROFESOR)
CREATE TABLE profesores (
    id_profesores      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuarios        BIGINT       NOT NULL UNIQUE,   -- 1 a 1 con usuarios
    id_tenants         BIGINT       NOT NULL,
    bio                TEXT,
    especialidad       VARCHAR(150),
    metodo_pago_token  VARCHAR(500),                    -- token OAuth (Mercado Pago Split) cifrado
    comision_pct       NUMERIC(5,2) NOT NULL DEFAULT 20.00,  -- % que cobra la plataforma
    creado_en          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_profesores_usuarios
        FOREIGN KEY (id_usuarios) REFERENCES usuarios (id_usuarios)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_profesores_tenants
        FOREIGN KEY (id_tenants) REFERENCES tenants (id_tenants)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_profesores_comision CHECK (comision_pct >= 0 AND comision_pct <= 100)
);

-- 3.3 Perfil de alumno (extiende a usuarios con rol ALUMNO)
CREATE TABLE alumnos (
    id_alumnos     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuarios    BIGINT      NOT NULL UNIQUE,        -- 1 a 1 con usuarios
    nivel          INT         NOT NULL DEFAULT 1,
    puntos_xp      INT         NOT NULL DEFAULT 0,
    racha_dias     INT         NOT NULL DEFAULT 0,
    creado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_alumnos_usuarios
        FOREIGN KEY (id_usuarios) REFERENCES usuarios (id_usuarios)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_alumnos_xp CHECK (puntos_xp >= 0 AND nivel >= 1 AND racha_dias >= 0)
);

-- =====================================================================
--  4) CURSOS Y CONTENIDO
-- =====================================================================

-- 4.1 Cursos
CREATE TABLE cursos (
    id_cursos      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_profesores  BIGINT       NOT NULL,
    id_categorias  BIGINT,
    id_tenants     BIGINT       NOT NULL,
    titulo         VARCHAR(200) NOT NULL,
    descripcion    TEXT,
    precio         NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    portada_url    VARCHAR(500),
    nivel          nivel_curso  NOT NULL DEFAULT 'PRINCIPIANTE',
    estado         estado_curso NOT NULL DEFAULT 'BORRADOR',
    creado_en      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    actualizado_en TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_cursos_profesores
        FOREIGN KEY (id_profesores) REFERENCES profesores (id_profesores)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_cursos_categorias
        FOREIGN KEY (id_categorias) REFERENCES categorias (id_categorias)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_cursos_tenants
        FOREIGN KEY (id_tenants) REFERENCES tenants (id_tenants)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_cursos_precio CHECK (precio >= 0)
);

-- 4.2 Modulos (secciones del curso)
CREATE TABLE modulos (
    id_modulos     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cursos      BIGINT       NOT NULL,
    titulo         VARCHAR(200) NOT NULL,
    orden          INT          NOT NULL DEFAULT 1,
    creado_en      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_modulos_cursos
        FOREIGN KEY (id_cursos) REFERENCES cursos (id_cursos)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_modulos_orden UNIQUE (id_cursos, orden)
);

-- 4.3 Lecciones
CREATE TABLE lecciones (
    id_lecciones    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_modulos      BIGINT       NOT NULL,
    titulo          VARCHAR(200) NOT NULL,
    tipo            tipo_leccion NOT NULL DEFAULT 'VIDEO',
    url_video       VARCHAR(500),                       -- URL firmada (Mux/Bunny)
    contenido_texto TEXT,
    orden           INT          NOT NULL DEFAULT 1,
    duracion_seg    INT          NOT NULL DEFAULT 0,
    es_gratis       BOOLEAN      NOT NULL DEFAULT FALSE, -- vista previa
    creado_en       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_lecciones_modulos
        FOREIGN KEY (id_modulos) REFERENCES modulos (id_modulos)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_lecciones_orden UNIQUE (id_modulos, orden),
    CONSTRAINT chk_lecciones_duracion CHECK (duracion_seg >= 0)
);

-- 4.4 Recursos descargables por leccion
CREATE TABLE recursos (
    id_recursos    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_lecciones   BIGINT       NOT NULL,
    nombre         VARCHAR(200) NOT NULL,
    url_archivo    VARCHAR(500) NOT NULL,
    tipo           VARCHAR(50),
    creado_en      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_recursos_lecciones
        FOREIGN KEY (id_lecciones) REFERENCES lecciones (id_lecciones)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =====================================================================
--  5) MATRICULA Y PROGRESO
-- =====================================================================

-- 5.1 Matriculas (alumno inscrito en un curso)
CREATE TABLE matriculas (
    id_matriculas  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_alumnos     BIGINT       NOT NULL,
    id_cursos      BIGINT       NOT NULL,
    estado         estado_matricula NOT NULL DEFAULT 'ACTIVA',
    progreso_pct   NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    fecha          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_matriculas_alumnos
        FOREIGN KEY (id_alumnos) REFERENCES alumnos (id_alumnos)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_matriculas_cursos
        FOREIGN KEY (id_cursos) REFERENCES cursos (id_cursos)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- Un alumno no puede matricularse dos veces al mismo curso
    CONSTRAINT uq_matriculas_alumno_curso UNIQUE (id_alumnos, id_cursos),
    CONSTRAINT chk_matriculas_progreso CHECK (progreso_pct >= 0 AND progreso_pct <= 100)
);

-- 5.2 Progreso por leccion
CREATE TABLE progreso_lecciones (
    id_progreso_lecciones BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_matriculas  BIGINT      NOT NULL,
    id_lecciones   BIGINT      NOT NULL,
    completada     BOOLEAN     NOT NULL DEFAULT FALSE,
    segundos_vistos INT        NOT NULL DEFAULT 0,
    fecha          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_progreso_matriculas
        FOREIGN KEY (id_matriculas) REFERENCES matriculas (id_matriculas)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_progreso_lecciones
        FOREIGN KEY (id_lecciones) REFERENCES lecciones (id_lecciones)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_progreso_matricula_leccion UNIQUE (id_matriculas, id_lecciones),
    CONSTRAINT chk_progreso_segundos CHECK (segundos_vistos >= 0)
);

-- =====================================================================
--  6) EVALUACION (quizzes)
-- =====================================================================

-- 6.1 Quizzes
CREATE TABLE quizzes (
    id_quizzes     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_lecciones   BIGINT       NOT NULL,
    titulo         VARCHAR(200) NOT NULL,
    nota_minima    NUMERIC(5,2) NOT NULL DEFAULT 60.00,
    creado_en      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_quizzes_lecciones
        FOREIGN KEY (id_lecciones) REFERENCES lecciones (id_lecciones)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_quizzes_nota CHECK (nota_minima >= 0 AND nota_minima <= 100)
);

-- 6.2 Preguntas
CREATE TABLE preguntas (
    id_preguntas   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_quizzes     BIGINT       NOT NULL,
    enunciado      TEXT         NOT NULL,
    tipo           tipo_pregunta NOT NULL DEFAULT 'OPCION_UNICA',
    orden          INT          NOT NULL DEFAULT 1,
    CONSTRAINT fk_preguntas_quizzes
        FOREIGN KEY (id_quizzes) REFERENCES quizzes (id_quizzes)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 6.3 Respuestas (opciones de cada pregunta)
CREATE TABLE respuestas (
    id_respuestas  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_preguntas   BIGINT       NOT NULL,
    texto          VARCHAR(500) NOT NULL,
    es_correcta    BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_respuestas_preguntas
        FOREIGN KEY (id_preguntas) REFERENCES preguntas (id_preguntas)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 6.4 Intentos de quiz por alumno
CREATE TABLE intentos_quiz (
    id_intentos_quiz BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_alumnos     BIGINT       NOT NULL,
    id_quizzes     BIGINT       NOT NULL,
    nota           NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    fecha          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_intentos_alumnos
        FOREIGN KEY (id_alumnos) REFERENCES alumnos (id_alumnos)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_intentos_quizzes
        FOREIGN KEY (id_quizzes) REFERENCES quizzes (id_quizzes)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_intentos_nota CHECK (nota >= 0 AND nota <= 100)
);

-- =====================================================================
--  7) CLASES EN VIVO
-- =====================================================================
CREATE TABLE clases_vivo (
    id_clases_vivo BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cursos      BIGINT       NOT NULL,
    id_profesores  BIGINT       NOT NULL,
    titulo         VARCHAR(200) NOT NULL,
    fecha_inicio   TIMESTAMPTZ  NOT NULL,
    url_sala       VARCHAR(500),                        -- Zoom/Meet/Jitsi
    url_grabacion  VARCHAR(500),                        -- queda como leccion
    estado         estado_clase_vivo NOT NULL DEFAULT 'PROGRAMADA',
    creado_en      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_clasesvivo_cursos
        FOREIGN KEY (id_cursos) REFERENCES cursos (id_cursos)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_clasesvivo_profesores
        FOREIGN KEY (id_profesores) REFERENCES profesores (id_profesores)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- =====================================================================
--  8) CERTIFICADOS Y PORTAFOLIO
-- =====================================================================

-- 8.1 Certificados verificables
CREATE TABLE certificados (
    id_certificados     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_alumnos          BIGINT       NOT NULL,
    id_cursos           BIGINT       NOT NULL,
    codigo_verificacion VARCHAR(80)  NOT NULL UNIQUE,   -- para URL de verificacion
    url                 VARCHAR(500),
    fecha_emision       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_certificados_alumnos
        FOREIGN KEY (id_alumnos) REFERENCES alumnos (id_alumnos)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_certificados_cursos
        FOREIGN KEY (id_cursos) REFERENCES cursos (id_cursos)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_certificados_alumno_curso UNIQUE (id_alumnos, id_cursos)
);

-- 8.2 Proyectos del portafolio (generado automaticamente)
CREATE TABLE proyectos_portafolio (
    id_proyectos_portafolio BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_alumnos     BIGINT       NOT NULL,
    id_cursos      BIGINT,
    titulo         VARCHAR(200) NOT NULL,
    descripcion    TEXT,
    url_repo       VARCHAR(500),
    creado_en      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_portafolio_alumnos
        FOREIGN KEY (id_alumnos) REFERENCES alumnos (id_alumnos)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_portafolio_cursos
        FOREIGN KEY (id_cursos) REFERENCES cursos (id_cursos)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- =====================================================================
--  9) PAGOS Y SUSCRIPCIONES
-- =====================================================================

-- 9.1 Pagos (compra de curso con split de comision)
CREATE TABLE pagos (
    id_pagos       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_alumnos     BIGINT       NOT NULL,
    id_cursos      BIGINT       NOT NULL,
    id_profesores  BIGINT       NOT NULL,               -- a quien se le liquida
    monto          NUMERIC(10,2) NOT NULL,
    comision       NUMERIC(10,2) NOT NULL DEFAULT 0.00, -- % plataforma sobre el monto
    metodo         metodo_pago  NOT NULL,
    estado         estado_pago  NOT NULL DEFAULT 'PENDIENTE',
    referencia_ext VARCHAR(150),                         -- id de transaccion de la pasarela
    fecha          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_pagos_alumnos
        FOREIGN KEY (id_alumnos) REFERENCES alumnos (id_alumnos)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pagos_cursos
        FOREIGN KEY (id_cursos) REFERENCES cursos (id_cursos)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pagos_profesores
        FOREIGN KEY (id_profesores) REFERENCES profesores (id_profesores)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_pagos_montos CHECK (monto >= 0 AND comision >= 0)
);

-- 9.2 Suscripciones (acceso a todo el catalogo)
CREATE TABLE suscripciones (
    id_suscripciones BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuarios    BIGINT       NOT NULL,
    plan           plan_suscripcion   NOT NULL,
    estado         estado_suscripcion NOT NULL DEFAULT 'PRUEBA',
    fecha_inicio   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    fecha_fin      TIMESTAMPTZ,
    CONSTRAINT fk_suscripciones_usuarios
        FOREIGN KEY (id_usuarios) REFERENCES usuarios (id_usuarios)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_suscripciones_fechas
        CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

-- 9.3 Cupones de descuento
CREATE TABLE cupones (
    id_cupones     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cursos      BIGINT,                               -- NULL = aplica a todo
    codigo         VARCHAR(50)  NOT NULL UNIQUE,
    descuento_pct  NUMERIC(5,2) NOT NULL,
    fecha_exp      TIMESTAMPTZ,
    usos_max       INT          NOT NULL DEFAULT 1,
    usos_actual    INT          NOT NULL DEFAULT 0,
    creado_en      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_cupones_cursos
        FOREIGN KEY (id_cursos) REFERENCES cursos (id_cursos)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_cupones_descuento CHECK (descuento_pct > 0 AND descuento_pct <= 100),
    CONSTRAINT chk_cupones_usos CHECK (usos_actual >= 0 AND usos_actual <= usos_max)
);

-- =====================================================================
-- 10) COMUNIDAD Y GAMIFICACION
-- =====================================================================

-- 10.1 Resenas de cursos
CREATE TABLE resenas (
    id_resenas     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_alumnos     BIGINT      NOT NULL,
    id_cursos      BIGINT      NOT NULL,
    estrellas      SMALLINT    NOT NULL,
    comentario     TEXT,
    fecha          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_resenas_alumnos
        FOREIGN KEY (id_alumnos) REFERENCES alumnos (id_alumnos)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_resenas_cursos
        FOREIGN KEY (id_cursos) REFERENCES cursos (id_cursos)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_resenas_alumno_curso UNIQUE (id_alumnos, id_cursos),
    CONSTRAINT chk_resenas_estrellas CHECK (estrellas BETWEEN 1 AND 5)
);

-- 10.2 Gamificacion (XP, badges, rachas)
CREATE TABLE gamificacion (
    id_gamificacion BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_alumnos     BIGINT      NOT NULL,
    tipo           tipo_gamificacion NOT NULL,
    valor          INT         NOT NULL DEFAULT 0,
    descripcion    VARCHAR(200),
    fecha          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_gamificacion_alumnos
        FOREIGN KEY (id_alumnos) REFERENCES alumnos (id_alumnos)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 10.3 Notificaciones
CREATE TABLE notificaciones (
    id_notificaciones BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuarios    BIGINT       NOT NULL,
    titulo         VARCHAR(200) NOT NULL,
    mensaje        TEXT,
    leida          BOOLEAN      NOT NULL DEFAULT FALSE,
    fecha          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_notificaciones_usuarios
        FOREIGN KEY (id_usuarios) REFERENCES usuarios (id_usuarios)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =====================================================================
-- 11) INDICES (rendimiento sobre FK y busquedas frecuentes)
-- =====================================================================
CREATE INDEX idx_usuarios_tenant        ON usuarios (id_tenants);
CREATE INDEX idx_usuarios_email         ON usuarios (email);
CREATE INDEX idx_profesores_tenant      ON profesores (id_tenants);
CREATE INDEX idx_cursos_profesor        ON cursos (id_profesores);
CREATE INDEX idx_cursos_categoria       ON cursos (id_categorias);
CREATE INDEX idx_cursos_tenant          ON cursos (id_tenants);
CREATE INDEX idx_cursos_estado          ON cursos (estado);
CREATE INDEX idx_modulos_curso          ON modulos (id_cursos);
CREATE INDEX idx_lecciones_modulo       ON lecciones (id_modulos);
CREATE INDEX idx_recursos_leccion       ON recursos (id_lecciones);
CREATE INDEX idx_matriculas_alumno      ON matriculas (id_alumnos);
CREATE INDEX idx_matriculas_curso       ON matriculas (id_cursos);
CREATE INDEX idx_progreso_matricula     ON progreso_lecciones (id_matriculas);
CREATE INDEX idx_progreso_leccion       ON progreso_lecciones (id_lecciones);
CREATE INDEX idx_quizzes_leccion        ON quizzes (id_lecciones);
CREATE INDEX idx_preguntas_quiz         ON preguntas (id_quizzes);
CREATE INDEX idx_respuestas_pregunta    ON respuestas (id_preguntas);
CREATE INDEX idx_intentos_alumno        ON intentos_quiz (id_alumnos);
CREATE INDEX idx_intentos_quiz          ON intentos_quiz (id_quizzes);
CREATE INDEX idx_clasesvivo_curso       ON clases_vivo (id_cursos);
CREATE INDEX idx_clasesvivo_fecha       ON clases_vivo (fecha_inicio);
CREATE INDEX idx_certificados_alumno    ON certificados (id_alumnos);
CREATE INDEX idx_portafolio_alumno      ON proyectos_portafolio (id_alumnos);
CREATE INDEX idx_pagos_alumno           ON pagos (id_alumnos);
CREATE INDEX idx_pagos_profesor         ON pagos (id_profesores);
CREATE INDEX idx_pagos_estado           ON pagos (estado);
CREATE INDEX idx_suscripciones_usuario  ON suscripciones (id_usuarios);
CREATE INDEX idx_resenas_curso          ON resenas (id_cursos);
CREATE INDEX idx_gamificacion_alumno    ON gamificacion (id_alumnos);
CREATE INDEX idx_notificaciones_usuario ON notificaciones (id_usuarios);
CREATE INDEX idx_notificaciones_leida   ON notificaciones (id_usuarios, leida);

-- =====================================================================
-- 12) TRIGGER: actualizar 'actualizado_en' automaticamente
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_actualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenants_upd  BEFORE UPDATE ON tenants
    FOR EACH ROW EXECUTE FUNCTION fn_actualizar_timestamp();
CREATE TRIGGER trg_usuarios_upd BEFORE UPDATE ON usuarios
    FOR EACH ROW EXECUTE FUNCTION fn_actualizar_timestamp();
CREATE TRIGGER trg_cursos_upd   BEFORE UPDATE ON cursos
    FOR EACH ROW EXECUTE FUNCTION fn_actualizar_timestamp();

-- =====================================================================
--  FIN DEL ESQUEMA
-- =====================================================================
