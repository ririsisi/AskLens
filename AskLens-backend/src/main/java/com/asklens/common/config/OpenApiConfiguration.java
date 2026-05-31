package com.asklens.common.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;

/**
 * Knife4j / SpringDoc OpenAPI 配置，支持 Bearer JWT 认证。
 * <p>
 * 页面右上角点 🔒 Authorize，粘贴 accessToken（纯 token，不加 Bearer 前缀），
 * 点 Authorize 确认后所有接口自动携带 Authorization header。
 */
@Configuration
public class OpenApiConfiguration {

    @Bean
    OpenAPI askLensOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("答镜AskLens API")
                        .description("答镜AskLens 知识库平台接口文档")
                        .version("1.0.0"));
    }
}
