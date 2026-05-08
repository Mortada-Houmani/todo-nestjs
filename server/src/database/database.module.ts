import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        url: config.get<string>('DATABASE_URL'),
        autoLoadEntities: true,
        synchronize: true,
        logging: true,
        ssl: config.get<string>('DATABASE_URL')?.includes('localhost') || config.get<string>('DATABASE_URL')?.includes('@postgres:') 
          ? false 
          : { rejectUnauthorized: false },
      }),
    }),
  ],
})
export class DatabaseModule {}