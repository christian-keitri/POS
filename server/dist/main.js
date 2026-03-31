"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const helmet_1 = require("helmet");
const app_module_1 = require("./app.module");
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule, {
        logger: ['error', 'warn', 'log', 'debug'],
    });
    const config = app.get(config_1.ConfigService);
    const port = config.get('port') ?? 3000;
    const origins = config.get('cors.origins') ?? [];
    app.use((0, helmet_1.default)());
    app.enableCors({
        origin: origins.length > 0 ? origins : true,
        credentials: true,
    });
    app.setGlobalPrefix('api');
    app.useGlobalPipes(new common_1.ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
        transformOptions: { enableImplicitConversion: false },
    }));
    await app.listen(port);
    common_1.Logger.log(`Server running on http://localhost:${port}/api`, 'Bootstrap');
}
bootstrap();
//# sourceMappingURL=main.js.map