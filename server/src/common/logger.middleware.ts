import { Injectable, NestMiddleware } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';

@Injectable()
export class LoggerMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const start = Date.now();
    console.log(`${req.method} ${req.originalUrl}`);

    res.on('finish', () => {
      const ms = Date.now() - start;
      console.log(`Handled in ${ms}ms`);
    });

    next();
  }
}

