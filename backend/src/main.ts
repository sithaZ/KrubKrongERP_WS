import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ConfigService } from '@nestjs/config';
import { ValidationPipe } from '@nestjs/common/pipes/validation.pipe';
import * as express from 'express';

async function bootstrap() {
  const app = await NestFactory.create(AppModule); 

  const configService = app.get(ConfigService);
  const port = configService.get<number>('PORT') || 3000;

  app.setGlobalPrefix('api');
  app.use(express.json({ limit: '5mb' }));
  app.use(express.urlencoded({ extended: true, limit: '5mb' }));


  //global validation pipe
    app.useGlobalPipes(
    new ValidationPipe({
      whitelist: false,           
      forbidNonWhitelisted: false, 
      transform: true,            
    }),
  );
  app.enableCors();
  
  await app.listen(port, '0.0.0.0');
  console.log(`Application is running on port: ${port}`);
}
bootstrap();
