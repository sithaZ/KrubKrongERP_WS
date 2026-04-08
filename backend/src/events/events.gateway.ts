import { WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server } from 'socket.io';


@WebSocketGateway({ cors: { origin: '*' } }) 
export class EventsGateway {
  
  @WebSocketServer()
  server: Server;

  
  notifyRoleChange(userId: string, newRole: string) {
    this.server.emit('roleUpdated', {
      userId: userId,
      role: newRole,
      message: 'Your permissions have been updated.'
    });
  }
}