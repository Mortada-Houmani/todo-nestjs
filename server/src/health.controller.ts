import { Controller, Get } from '@nestjs/common';
// push test for my project kereo3
@Controller('health')
export class HealthController {
  @Get()
  check() {
    return {
      status: 'ok',
      version: 'fullName-register-fix-v1',
      timestamp: new Date().toISOString(),
    };
  }
}
